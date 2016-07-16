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
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=36540187')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("ワンワン霊体験 (by 押切蓮介)\nhttp://embed.pixiv.net/decorate.php?illust_id=36540187#.jpg")
  end

  it 'pixiv2' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?illust_id=16125568&mode=medium')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`ちだまりスティック \(by .*ジェ.*\)\nhttp://embed\.pixiv\.net/decorate\.php\?illust_id=16125568#\.jpg`)
  end

  it 'pixiv R-18' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=53233364')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^\[R-18\] Teaching Feeling ~奴隷との生活~ \(by Ray-Kbys\)\nhttp://.+\.pixiv\.net/c/64x64/img-\w+/img/.+\.jpg$`)
  end

  it 'pixiv R-18 ugoila' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=55721718')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^\[R-18\] 純愛ックス \(by Ray-Kbys\)\nhttp://.+\.pixiv\.net/c/64x64/img-\w+/img/.+\.jpg$`)
  end

  it 'pixiv R-18G' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=40455206')
    expect(last_response).to be_ok
    expect(last_response.body).to match('[R-18G] 夜道でばったり (by 田口綺麗)')
  end

  it 'nijie' do
    post '/', create_message_json('http://nijie.info/view.php?id=23460')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("（粘膜）密着！スペルマポリス２４ | ぶぶのすけ\nhttps://pic02.nijie.info/small_light%28dw=70%29/nijie_picture/2908_20120912222900.jpg")
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
