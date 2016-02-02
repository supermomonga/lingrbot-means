# encoding: utf-8

ENV['RACK_ENV'] = 'test'

require_relative '../app'
require_relative './spec_helper'
require 'json'
require 'rack/test'

describe 'The Semantics=san' do
  include Rack::Test::Methods

  def app
    Bot
  end

  it 'web' do
    get '/'
    expect(last_response).to be_ok
  end

  it 'ping' do
    post '/', create_message_json('ping')
    expect(last_response).to be_ok
    expect(last_response.body).to eq('pong')
  end

  it 'seiga' do
    post '/', create_message_json('http://seiga.nicovideo.jp/seiga/im5479269')
    expect(last_response).to be_ok
    expect(last_response.body).to eq('http://lohas.nicoseiga.jp/thumb/5479269i#.png')
  end

  it 'twitter' do
    post '/', create_message_json('https://twitter.com/kumikumitm/status/693000092534587392')
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Kumi TM (@kumikumitm) - 1RT / 5Fav 2016/01/29 18:17:52
#ggjsap @raa0121 働いておる https://t.co/Czqc94p4yg
https://pbs.twimg.com/media/CZ4H5jxWkAAHC6w.jpg
https://pbs.twimg.com/media/CZ4H6I5WcAAbBGo.jpg')
  end

  it 'pixiv' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=54003739')
    expect(last_response).to be_ok
    expect(last_response.body).to eq('【アイドルマスターシンデレラガールズ】「【サンプルと告知】志乃楓合同発行します【12/18　追記あり】」イラスト/紺@木曜西ち17b [pixiv]')
  end
end
