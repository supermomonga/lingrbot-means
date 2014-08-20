# encoding: utf-8

require 'bundler'
Bundler.require

require 'sinatra/reloader' if development?

LingrBot.configure do |config|
  config.id     = ENV['BOT_ID']
  config.secret = ENV['BOT_SECRET']
end

class Bot < Sinatra::Base

  configure :development do
    register Sinatra::Reloader
  end

  def initialize *args
    @agent = Mechanize.new
    @agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @twitter = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_SECRET']
    end
    @pixiv = Pixiv.client ENV['PIXIV_ID'], ENV['PIXIV_PASSWORD'] do |config|
      config.user_agent_alias = 'Mac Safari'
    end
    super
  end

  post '/' do
    Thread.new do
      begin
        JSON.parse(request.body.read)['events'].map{ |e|
          e['message']
        }.each do |m|
          text = m['text']
          room_id = m['room']
          response =
            case text
            when /^ping$/ then 'pong'
            when %r`http://(?:www|touch)?\.pixiv\.net/member\.php\?id=(\d+)` then pixiv_member($1)
            when %r`https://twitter\.com/[^\/]+/status(?:es)?/(\d+)(?:\/photo\/\d+)?$` then twitter_media_url($1.to_i)
            when %r`http://d\.pr/i/(\w+)$` then droplr_raw_url($1)
            when %r`(http://gyazo\.com/\w+)$` then gyazo_raw_url($1)
            else nil
            end
          if response
            puts "say to `#{room_id}`:"
            response.tap{|r| break [r] unless r.class == Array }.each do |r|
              puts r
              LingrBot.say(room_id, r)
            end
          end
        end
      rescue => e
        puts e
      end
    end
    content_type :text
    ''
  end

  get '/' do
    content_type :text
    'Still Alive'
  end

  private
  def gyazo_raw_url(url)
    res = @agent.get url
    res.at('meta[name="twitter:image"]').attr 'content' if res.code == '200'
  end

  def droplr_raw_url(id)
    # Official raw url format is `http://d.pr/i/#{id}+`
    # but use another way for client compatibility.
    "http://d.pr/i/#{id}.png"
  end

  def twitter_media_url(status_id)
    s = @twitter.status status_id
    s.media.map(&:media_url_https).join("\n") if s.media?
  end

  def pixiv_member(id)
    member = @pixiv.member(id)
    <<-EOS
#{member.profile_image_url}
#{member.name} (#{member.pixiv_id})
http://www.pixiv.net/member.php?id=#{id}
    EOS
  end

end
