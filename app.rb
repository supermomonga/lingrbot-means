# encoding: utf-8

require 'bundler'
Bundler.require
require 'erb'
require 'open-uri'
require 'digest/sha1'
require 'addressable/uri'
require 'uri'
require 'webrick/httputils'

require 'sinatra/reloader' if development?

class Bot < Sinatra::Base

  configure :development do
    register Sinatra::Reloader
  end

  def initialize *args
    init_mechanize
    init_redis
    init_gyazo
    init_twitter
    spawn_worker
    super
  end

  post '/' do
    if ENV['RACK_ENV'] == 'test'
      JSON.parse(request.body.read)['events'].map{ |e|
        handle_message e['message']
      }.join("\n")
    else
      enqueue *JSON.parse(request.body.read)['events'].map{ |e|
        e['message']
      }
      content_type :text
      ''
    end
  end

  get '/' do
    content_type :text
    'Still Alive'
  end

  private
  def init_mechanize
    @agent = Mechanize.new
    @agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @agent.user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.0 Safari/537.36'
    @agent.request_headers = {
      'Accept-Encoding' => 'gzip,deflate,sdch',
      'Accept-Language' => 'ja,en-US;q=0.8,en;q=0.6'
    }
  end

  def init_redis
    uri = URI.parse ENV['REDISCLOUD_URL'] || 'redis://localhost:6379'
    @redis = Redis.new host: uri.host, port: uri.port, password: uri.password
  end

  def init_gyazo
    @gyazo = Gyazo::Client.new
    @gyazo.host = ENV['GYAZO_HOST'] || 'http://gyazo.com'
  end

  def init_twitter
    @twitter = Twitter::REST::Client.new do |config|
      config.bearer_token        = ENV['TWITTER_BEARER_TOKEN'] || YAML.load_file('.travis.yml')['env']['global'].split('=')[1].delete("'")
    end
  end

  def init_queues
    puts "Initialize queues." unless @queues
    @queues ||= []
  end

  def enqueue message
    puts "Enqueued."
    @queues.push message
  end

  def dequeue
    puts "Dequeued."
    @queues.shift
  end

  def spawn_worker
    init_queues
    EM:: defer do
      loop do
        sleep 0.5
        next if @queues.empty?
        begin
          message = dequeue
          response = handle_message message
          say message['room'], response if response
          puts "Didn't match." unless response
        rescue => e
          puts "Got error: #{e}"
        end
      end
    end
  end

  def handle_message message
    text = message['text']
    if text == 'ping'
      'pong'
    else
      results = []
      while text.size > 0
        remainder, result = process_pattern text
        if remainder.nil?
          text = ''
        else
          results << result
          text = remainder
        end
      end
      results.join("\n")
    end
  end

  def process_pattern text
    patterns = {
      %r`(https?://(?:www\.nicovideo\.jp/watch|nico\.ms)/((?:sm|nm)?\d+))` =>
        proc { nicovideo($1, $2) },
      %r`https?://live\.nicovideo\.jp/gate/(lv\d+)` =>
        proc { nicolive_gate($1) },
      %r`https?://(?:www|touch)?\.pixiv\.net/member_illust\.php.*illust_id=(\d+)` =>
        proc { pixiv_illust($1) },
      %r`https?://nijie\.info/view\.php\?id=(\d+)` =>
        proc { nijie_illust($1) },
      %r`https?://(?:mobile\.)?twitter\.com/[^\/]+/status(?:es)?/(\d+)(?:\/photo\/\d+)?$` =>
        proc { twitter_content($1.to_i) },
      %r`https?://d\.pr/i/(\w+)$` =>
        proc { droplr_raw_url($1) },
      %r`https?://seiga\.nicovideo\.jp/seiga/im(\d+)` =>
        proc { nicoseiga_image_url($1.to_i) },
      %r`(https?://seiga\.nicovideo\.jp/watch/mg\d+)` =>
        proc { nicoseiga_comic_thumb_url($1) },
      %r`(https?://seiga\.nicovideo\.jp/comic/\d+)` =>
        proc { nicoseiga_comic_main_url($1) },
      %r`(https?://gyazo\.com/\w+)$` =>
        proc { gyazo_raw_url($1) },
      %r`https?://ow\.ly/i/(\w+)` =>
        proc { owly_raw_url($1) },
      %r`(https?://\w+\.\w.yimg.jp/.+)` =>
        proc { append_extension $1 },
      %r`(https?://.+-origin\.fc2\.com/.+\.(?:jpe?g|gif|png))$` =>
        proc { fc2_blog_url $1 },
      %r`(https?://b.hatena.ne.jp/entry/\d+/comment/[^\s]+)$` =>
        proc { hatenabookmark_comment $1 },
      %r`(https?://ask.fm/.+/answer/\d+)` =>
        proc { askfm $1 },
      %r`https?://p.twipple.jp/(\w+)` =>
        proc { twipple_photo $1 },
      %r`(https?://www.irasutoya.com/\d+/\d+/[a-z0-9_-]+.html)` =>
        proc { irasutoya_illust $1 },
      %r`https?://www.dropbox.com/(.+\.(?:jpe?g|gif|png))\?dl=0` =>
        proc { dropbox_image_raw_url $1 },
      %r`(https?://i.imgur.com/[0-9a-zA-Z]+\.gif)v` =>
        proc { $1 },
      %r`(https?://[^\s]+)` =>
        proc { title_for_url $1 }
    }
    patterns.each { |regexp, process|
      if regexp.match(text)
        remainder = $'
        return [remainder, process.call]
      end
    }
    [nil, nil]
  end

  def say room_id, message
    message = convert_emoji message
    case ENV['RACK_ENV']
    when 'development'
      puts "say to `#{room_id}`:"
      puts decode_for_lingr message
    when 'test'
    else
      id     = ENV['BOT_ID']
      secret = ENV['BOT_SECRET']
      verifier = Digest::SHA1.hexdigest id + secret
      message_encoded = ERB::Util.url_encode(decode_for_lingr message)
      request_url = "http://lingr.com/api/room/say?room=#{room_id}&bot=#{id}&text=#{message_encoded}&bot_verifier=#{verifier}"
      open request_url
    end
  end

  def decode_for_lingr message
    message.gsub(/&(lt|gt);/, {
                   '&lt;' => '<',
                   '&gt;' => '>'
                 })
  end

  def convert_emoji text
    EmojiParser.parse_unicode(text) {|emoji|
      "[%s]" % emoji.name
    }
  end

  def get_headers url
    headers = {}
    uri = URI.parse url
    begin
      http = Net::HTTP.start uri.host, uri.port
      request = Net::HTTP::Get.new uri.request_uri
      http.request request do |response|
        headers = response.to_hash
        break
      end
    rescue IOError
    end
    return headers
  end

  def append_extension url, extension = :jpg
    if has_extension? url
      url
    else
      "#{url}#.#{extension}"
    end
  end

  def has_extension? url
    url.match /\.(jpe?g|gif|png)$/i
  end

  def gyazo_create url, referer = nil
    if url.match /(jpe?g|gif|png)$/
      ext = $1
    else
      # FIXME: check file type
      ext = "png"
    end
    temp_file = "tmpimage_#{Time.now.to_i}.#{ext}"
    referer ||= url.gsub /(http:\/\/[^\/]+\/).*$/, '\1'
    @agent.get(url, nil, referer, nil).save "./#{temp_file}"
    gyazo_url = @gyazo.upload "#{temp_file}"
    File.delete temp_file
    gyazo_raw_url gyazo_url
  end

  def gyazo_raw_url url
    res = @agent.get url
    res.at('meta[name="twitter:image"]').attr 'content' if res.code == '200'
  end

  def droplr_raw_url id
    # Official raw url format is `http://d.pr/i/#{id}+`
    # but use another way for client compatibility.
    "http://d.pr/i/#{id}.png"
  end

  def twitter_content status_id
    s = @twitter.status status_id
    name = s.attrs[:user][:name]
    date = s.created_at.getlocal("+09:00").strftime('%Y/%m/%d %H:%M:%S')
    screen_name = s.attrs[:user][:screen_name]
    text = "%s (@%s) - %sRT / %sFav %s\n%s" % [ name, screen_name, number_format(s.retweet_count), number_format(s.favorite_count), date, s.text ]
    if s.media?
      s.media.each do |medium|
        case medium
        when Twitter::Media::Photo
          text << "\n" << medium.media_url_https
        when Twitter::Media::Video, Twitter::Media::AnimatedGif
          text << "\n" << medium.video_info.variants.select{ |v| v.content_type == 'video/mp4' }.max{ |a, b| a.bitrate <=> b.bitrate }.attrs[:url]
        end
      end
    end
    text.gsub!(/(?=\n)(?<=\n)/m, '　')
    # require 'pp'
    # pp s.attrs
    text
  end

  def pixiv_illust id
    res = @agent.get "http://www.pixiv.net/member_illust.php?illust_id=#{id}&mode=medium"
    if res.code == '200'
      meta = res.at('meta[property="og:title"]').attr('content')
      r18 = res.at('.twitter-share-button').attr('data-text').include?('[R-18]')
      r18g = res.at('.twitter-share-button').attr('data-text').include?('[R-18G]')
      ugoila = res.at('.twitter-share-button').attr('data-text').include?('#うごイラ')
      title, author = meta.scan(/「([^」]+)」/).flatten
      illust_url = res.at('meta[property="og:image"]').attr('content')
      # for R-18 illust
      if illust_url.empty?
        if ugoila
          illust_url = res.at('.selected_works img').attr('src').gsub('128x128', '64x64')
        else
          illust_url = res.at('.sensored img').attr('src')
        end
      end
      if r18
        "[R-18] %s (by %s)\n%s" % [ title, author, append_extension(illust_url) ]
      elsif r18g
        "[R-18G] %s (by %s)" % [ title, author ]
      else
        "%s (by %s)\n%s" % [ title, author, append_extension(illust_url) ]
      end
    end
  end

  def nijie_illust id
    res = @agent.get "http://nijie.info/view.php?id=#{id}"
    if res.code == '200'
      title = res.at('meta[property="og:title"]').attr('content')
      illust_url = res.at('meta[property="og:image"]').attr('content').gsub(/nijie_picture\/sp/, 'small_light(dw=70)/nijie_picture').gsub(/^http:/, 'https:')
      "%s\n%s" % [ title, illust_url ]
    end
  end

  def nicolive_gate id
    res = @agent.get "http://live.nicovideo.jp/gate/#{id}"
    res.at('meta[property="og:image"]').attr('content') if res.code == '200'
  end

  def nicovideo url, id
    res = @agent.get "http://ext.nicovideo.jp/api/getthumbinfo/#{id}"
    return nil unless res.code == '200'
    thumb_small = res.at('thumbnail_url').inner_text
    thumb_large = "#{thumb_small}.L"
    headers = get_headers thumb_large
    p headers["content-type"]
    thumb_url = if headers["content-type"][0] == "image/jpeg"
      thumb_large
    else
      thumb_small
    end
    title = title_for_url url
    "#{title}\n#{thumb_url}#.jpg"
  end

  def nicoseiga_image_url id
    "http://lohas.nicoseiga.jp/thumb/#{id}i#.png"
  end

  def nicoseiga_comic_thumb_url url
    res = @agent.get url
    "%s#.png" % res.at('meta[property="og:image"]').attr('content') if res.code == '200'
  end

  def nicoseiga_comic_main_url url
    res = @agent.get url
    "%s#.png" % res.at('.main_visual img').attr('src') if res.code == '200'
  end

  def owly_raw_url id
    # ow.ly will convert all image types to jpg
    "http://static.ow.ly/photos/normal/#{id}.jpg"
  end

  def fc2_blog_url url
    gyazo_create url
  end

  def hatenabookmark_comment url
    res = @agent.get url
    container = res.at('.comment-container')
    comment = container.at('.comment-body').inner_text
    author = container.at('.comment-author .user-link').inner_text
    stars_url = "http://s.hatena.ne.jp//entry.json?uri=%s" % ERB::Util.url_encode(container.at('.comment-date a').attribute('href'))
    json = JSON.parse @agent.get(stars_url).body
    stars = json['entries'].first['stars'].size
    return "%s: %s" % [author, comment] if stars == 0
    return "★%d %s: %s" % [stars, author, comment]
  end

  def askfm url
    res = @agent.get url
    q = res.at('.question').inner_text
    a = res.at('.answer').inner_text
    return "Q: %s\nA: %s" % [q, a]
  end

  def twipple_photo id
    "http://p.twpl.jp/show/large/#{id}#.jpg"
  end

  def irasutoya_illust url
    res = @agent.get url
    title = res.at('.title h2').inner_text.strip
    images = res.search('.entry a img').map{|it| it['src']}.join "\n"
    description = res.search('.entry .separator')[1].inner_text.strip
    return "【#{title}】\n#{description}\n#{images}"
  end

  def dropbox_image_raw_url url
    "https://dl.dropboxusercontent.com/#{url}"
  end

  def has_not_linkable_char? url
    url.bytes do |b|
      return true if  (b & 0b10000000) != 0
    end
    return true if url.include?('[') or url.include?(']')
    false
  end

  def escape_url url
    addressable_url = Addressable::URI.parse(url)
    path = WEBrick::HTTPUtils.escape(addressable_url.path)
    "#{addressable_url.normalized_site}#{path}#{addressable_url.normalized_query ? "?#{addressable_url.normalized_query}" : ''}"
  end

  def scrape_title url
    res = @agent.get url
    if res.code == '200' && res['Content-Type'].include?('text/html')
      title = res.at('title').tap{|it|break it.inner_text if it} ||
        res.at('meta[property="og:title"]').tap{|it|it.attr('content') if it} ||
        res.at('meta[property="twitter:title"]').tap{|it|it.attr('content') if it}
      if title
        return title
      end
    end
    nil
  end

  def title_for_url url
    not_linkable = has_not_linkable_char? url
    url = escape_url(url) if not_linkable
    title = scrape_title url
    result = []
    result << url if not_linkable
    result << title if title
    result.join("\n")
  end

  def number_format n
    n.to_s.reverse.chars.each_slice(3).map(&:join).join(',').reverse
  end

end
