# encoding: utf-8

require 'bundler'
Bundler.require

require 'sinatra/reloader' if development?

LingrBot.configure do |config|
  config.id     = ENV['BOT_ID']
  config.secret = ENV['BOT_SECRET']
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
          when /ping/ then 'pong'
          else nil
          end
        LingrBot.say(room_id, response) if response
      end
    rescue e
    end
  end
  content_type :text
  ''
end

get '/' do
  content_type :text
  'Still Alive'
end
