# encoding: utf-8

require 'bundler'
Bundler.require
require 'erb'
require 'open-uri'
require 'digest/sha1'

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
    init_pixiv
    spawn_worker
    super
  end

  post '/' do
    enqueue *JSON.parse(request.body.read)['events'].map{ |e|
      e['message']
    }
    content_type :text
    ''
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
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_SECRET']
    end
  end

  def init_pixiv
    # @pixiv = Pixiv.client ENV['PIXIV_ID'], ENV['PIXIV_PASSWORD'] do |config|
    #   config.user_agent_alias = 'Mac Safari'
    # end
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
          handle_message dequeue
        rescue => e
          puts "Got error: #{e}"
        end
      end
    end
  end

  def handle_message message
    message.split(/\s+/).each do |x|
      response =
        case x
        when /^ping$/
          'pong'
        when %r`(http://(?:www\.nicovideo\.jp/watch|nico\.ms)/((?:sm|nm)?\d+))`
          nicovideo($1, $2)
        when %r`http://live\.nicovideo\.jp/gate/(lv\d+)`
          nicolive_gate($1)
        # when %r`http://(?:www|touch)?\.pixiv\.net/member\.php\?id=(\d+)`
        #   pixiv_member($1)
        when %r`https?://(?:mobile\.)?twitter\.com/[^\/]+/status(?:es)?/(\d+)(?:\/photo\/\d+)?$`
          twitter_content($1.to_i)
        when %r`http://d\.pr/i/(\w+)$`
          droplr_raw_url($1)
        when %r`http://seiga\.nicovideo\.jp/seiga/im(\d+)`
          nicoseiga_image_url($1.to_i)
        when %r`(http://seiga\.nicovideo\.jp/watch/mg\d+)`
          nicoseiga_comic_thumb_url($1)
        when %r`(http://seiga\.nicovideo\.jp/comic/\d+)`
          nicoseiga_comic_main_url($1)
        when %r`(http://gyazo\.com/\w+)$`
          gyazo_raw_url($1)
        when %r`http://ow\.ly/i/(\w+)`
          owly_raw_url($1)
        when %r`(http://\w+\.\w.yimg.jp/.+)`
          append_extension $1
        when %r`(http://.+-origin\.fc2\.com/.+\.(?:jpe?g|gif|png))$`
          fc2_blog_url $1
        when %r`(https?://b.hatena.ne.jp/entry/\d+/comment/[^\s]+)$`
          hatenabookmark_comment $1
        when %r`(https?://ask.fm/.+/answer/\d+)`
          askfm $1
        when %r`https?://p.twipple.jp/(\w+)`
          twipple_photo $1
        when %r`(https?://[^\s]+)`
          title_for_url $1
        end
      say message['room'], response if response
      puts "Didn't match." unless response
    end
  end

  def say room_id, message
    message = convert_emoji message
    if ENV['RACK_ENV'] == 'development'
      puts "say to `#{room_id}`:"
      puts message
    else
      id     = ENV['BOT_ID']
      secret = ENV['BOT_SECRET']
      verifier = Digest::SHA1.hexdigest id + secret
      message_encoded = ERB::Util.url_encode message
      request_url = "http://lingr.com/api/room/say?room=#{room_id}&bot=#{id}&text=#{message_encoded}&bot_verifier=#{verifier}"
      open request_url
    end
  end

  def convert_emoji text
    text.chars.map{|chr|
      chr.tap{|chr|
        emoji = Emoji.find_by_unicode chr
        break "[%s]" % emoji.name if emoji
      }
    }.join
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
    screen_name = s.attrs[:user][:screen_name]
    text = "%s (@%s) - %sRT / %sFav\n%s" % [ name, screen_name, number_format(s.retweet_count), number_format(s.favorite_count), s.text ]
    text << "\n" << s.media.map(&:media_url_https).join("\n") if s.media?
    # require 'pp'
    # pp s.attrs
    text
  end

  def pixiv_member id
    member = @pixiv.member id
    member.profile_image_url
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

  def title_for_url url
    res = @agent.get url
    if res.code == '200' && res['Content-Type'].include?('text/html')
      title = res.at('title').tap{|it|break it.inner_text if it} ||
        res.at('meta[property="og:title"]').tap{|it|it.attr('content') if it} ||
        res.at('meta[property="twitter:title"]').tap{|it|it.attr('content') if it}
      return title if title
    end
  end

  def number_format n
    n.to_s.reverse.chars.each_slice(3).map(&:join).join(',').reverse
  end

end
