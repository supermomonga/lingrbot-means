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

  it 'ping inside others' do
    post '/', create_message_json("わたし\nping\n大好きです")
    expect(last_response).to be_ok
    expect(last_response.body).to eq('')
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
    expect(last_response.body).to eq("【サンプルと告知】志乃楓合同発行します【12/18　追記あり】 (by 紺@シンステ　レ-8)\nhttp://embed.pixiv.net/decorate.php?illust_id=54003739#.jpg")
  end

  it 'pixiv2' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?illust_id=57708370&mode=medium')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("土曜の昼とかにランチ作るエリみほ (by 梵辛@３日目東ニ５４ｂ)\nhttp://embed.pixiv.net/decorate.php?illust_id=57708370#.jpg")
  end

  it 'pixiv R-18' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=57723566')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^\[R-18\] 生命に危険を及ぼす程のオシャレ \(by 山田の性活が第一\)\nhttp://.+\.pixiv\.net/c/\d+x\d+/img-\w+/img/.+\.jpg$`)
  end

  it 'multi URL' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=54003739 https://twitter.com/kumikumitm/status/693000092534587392')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("【サンプルと告知】志乃楓合同発行します【12/18　追記あり】 (by 紺@シンステ　レ-8)
http://embed.pixiv.net/decorate.php?illust_id=54003739#.jpg
Kumi TM (@kumikumitm) - 1RT / 5Fav 2016/01/29 18:17:52
#ggjsap @raa0121 働いておる https://t.co/Czqc94p4yg
https://pbs.twimg.com/media/CZ4H5jxWkAAHC6w.jpg
https://pbs.twimg.com/media/CZ4H6I5WcAAbBGo.jpg")
  end

  it 'multi URL with multi line' do
    post '/', create_message_json('http://avex.jp/pripara/discography/detail.php?id=1010630
1
http://avex.jp/pripara/1st/discography/
2')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("プリパラ☆ミュージックコレクションDX／プリパラ☆ミュージックコレクション DVD/CD | TVアニメ「プリパラ」DVD・CD公式ホームページ
DVD/CD | TVアニメ「プリパラ」BD・DVD・CD公式ホームページ")
  end
end
