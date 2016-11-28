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

  it 'twitter with new emoji' do
    post '/', create_message_json('https://twitter.com/hosoekota0405/status/795919338855243781')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^.+ \(@\w+\) - [\d,]+RT / [\d,]+Fav 2016/11/08 18:22:12
球技大会なかなか楽しかったのことですね\[:table_tennis_paddle_and_ball:\]$`)
  end

  it 'twitter has params' do
    post '/', create_message_json('https://twitter.com/mattn_jp/status/798035328535818240?ref_src=twsrc%5Etfw')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^.+ \(@\w+\) - [\d,]+RT / [\d,]+Fav 2016/11/14 14:30:23
そうだね$`)
  end

  it 'twitter expanded URL' do
    post '/', create_message_json('https://twitter.com/nulltarou2/status/758963721494331393')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^.+ \(@\w+\) - [\d,]+RT / [\d,]+Fav 2016/07/29 18:53:46
歌詞が更にじわる https://twitter\.com/kawa988/status/758840448001593344$`)
  end

  it 'twitter animated GIF' do
    post '/', create_message_json('https://twitter.com/gusmachine/status/789087037030739968')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^.+ \(@\w+\) - [\d,]+RT / [\d,]+Fav 2016/10/20 21:53:04
twitter, 投稿の際に下のGIFってやつ選んで Hillary って入力すると凄いGIFが無限に出てくる。 https://t\.co/UszmuiIdnd
https://pbs\.twimg\.com/tweet_video/CvNmdqDUMAAt0j0\.mp4$`)
  end

  it 'twitter video' do
    post '/', create_message_json('https://twitter.com/porterrobinson/status/790305156545941504')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^.+ \(@\w+\) - [\d,]+RT / [\d,]+Fav 2016/10/24 06:33:27
i took this video at the first voiceover session for shelter\. can't describe the chills i felt hearing misawa's voice for the first time :'\) https://t.co/aG5yQa4P1W
https://video\.twimg\.com/ext_tw_video/790304971933626369/pu/vid/720x1280/q0gz_peypV0mwF8r\.mp4$`)
  end

  it 'twitter video long URL' do
    post '/', create_message_json('https://twitter.com/tomato_dayo/status/797753682087395329/video/1')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^.+ \(@\w+\) - [\d,]+RT / [\d,]+Fav 2016/11/13 19:51:14
放課後ミッドナイターズ　細かい動作描写に笑える https://t.co/JWcPxpO1i4
https://video\.twimg\.com/ext_tw_video/797753098538098688/pu/vid/640x360/2Bw6FUaCQnW_gu7F\.mp4$`)
  end

  it 'twitter photo' do
    post '/', create_message_json('http://twitter.com/yurang92/status/756450385854799872/photo/1')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^.+ \(@\w+\) - [\d,]+RT / [\d,]+Fav 2016/07/22 20:26:40
ちょっと遅くなったけどにこちゃん誕生日おめでと！ #矢澤にこ生誕祭2016 https://t\.co/H8t7iravWD
https://pbs\.twimg\.com/media/Cn9zdJ5UEAI3wjk\.jpg$`)
  end

  it 'twitter photo and params' do
    post '/', create_message_json('http://twitter.com/yurang92/status/756450385854799872/photo/1?ref_src=twsrc%5Etfw')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^.+ \(@\w+\) - [\d,]+RT / [\d,]+Fav 2016/07/22 20:26:40
ちょっと遅くなったけどにこちゃん誕生日おめでと！ #矢澤にこ生誕祭2016 https://t\.co/H8t7iravWD
https://pbs\.twimg\.com/media/Cn9zdJ5UEAI3wjk\.jpg$`)
  end

  it 'twitter long tweet' do
    post '/', create_message_json('https://twitter.com/hanomidori/status/789839578941169664')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^.+ \(@\w+\) - [\d,]+RT / [\d,]+Fav 2016/10/22 23:43:24
明日のコミティアはL38a「はのみ堂」にて委員長おしっこ我慢本「クラス委員はくじけない！」を500円にて頒布いたします。今回スケブは受け付けません。色紙は希望者が居たら終わり頃差し上げますので、ツイッター告知時間に集合して頂ければと思います。 https://t\.co/S6IbB8xmXI
https://pbs\.twimg\.com/media/CvYS5DzUAAAnnEa\.jpg$`)
  end

  it 'twitter moments' do
    post '/', create_message_json('https://twitter.com/i/moments/789448724648857601')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`デレマス絵まとめ\(4月～10月\) - .+ \(@\w+\) - 2016/10/21 13:52
イラスト、漫画、キャラごちゃまぜです。`)
  end

  it 'twitter moments mobile' do
    post '/', create_message_json('https://mobile.twitter.com/i/moments/789448724648857601')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`デレマス絵まとめ\(4月～10月\) - .+ \(@\w+\) - 2016/10/21 13:52
イラスト、漫画、キャラごちゃまぜです。`)
  end

  it 'pixiv' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=36585065')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("ひぐらし (by 押切蓮介)\nhttp://embed.pixiv.net/decorate.php?illust_id=36585065#.jpg")
  end

  it 'pixiv2' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?illust_id=16125568&mode=medium')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`ちだまりスティック \(by .*ジェ.*\)\nhttp://embed\.pixiv\.net/decorate\.php\?illust_id=16125568#\.jpg`)
  end

  it 'pixiv manga when medium' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=59271735')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("ハルちゃんは弱い(2) (by らっパル) 漫画\nhttp://embed.pixiv.net/decorate.php?illust_id=59271735#.jpg")
  end

  it 'pixiv manga_big' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=manga_big&illust_id=56962791&page=9')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("SmileING TaleS 01 (by リョーサン)\nhttp://embed.pixiv.net/decorate.php?illust_id=56962791&page=9#.jpg")
  end

  it 'pixiv manga_big R-18' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=manga_big&illust_id=55155738')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^\[R-18\] 愛里寿ちゃん始めてのドキドキ自画撮り \(by むおと\)\nhttp://.+\.pixiv\.net/c/64x64/img-\w+/img/.+p0_square1200\.jpg$`)
  end

  it 'pixiv manga_big R-18 with page' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=manga_big&illust_id=55240249&page=1')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^\[R-18\] 無題 \(by もつあき\)\nhttp://.+\.pixiv\.net/c/64x64/img-\w+/img/.+p1_square1200\.jpg$`)
  end

  it 'pixiv R-18' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=53233364')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^\[R-18\] Teaching Feeling ~奴隷との生活~ \(by Ray-Kbys\)\nhttp://.+\.pixiv\.net/c/64x64/img-\w+/img/.+\.jpg$`)
  end

  it 'pixiv ugoila' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=58024542')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("...♡ (by ひとで) うごイラ\nhttp://embed.pixiv.net/decorate.php?illust_id=58024542#.jpg")
  end

  it 'pixiv R-18 ugoila' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=55721718')
    expect(last_response).to be_ok
    expect(last_response.body).to match(%r`^\[R-18\] 純愛ックス \(by Ray-Kbys\) うごイラ\nhttp://.+\.pixiv\.net/c/64x64/img-\w+/img/.+\.jpg$`)
  end

  it 'pixiv R-18G' do
    post '/', create_message_json('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=40455206')
    expect(last_response).to be_ok
    expect(last_response.body).to match('[R-18G] 夜道でばったり (by 田口綺麗)')
  end

  it 'nijie' do
    post '/', create_message_json('http://nijie.info/view.php?id=23460')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("（粘膜）密着！スペルマポリス２４ | ぶぶのすけ\nhttps://pic02.nijie.info/small_light(dw=70)/nijie_picture/2908_20120912222900.jpg")
  end

  it 'sp nijie' do
    post '/', create_message_json('http://sp.nijie.info/view.php?id=23460')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("（粘膜）密着！スペルマポリス２４ | ぶぶのすけ\nhttps://pic02.nijie.info/small_light(dw=70)/nijie_picture/2908_20120912222900.jpg")
  end

  it 'deviantART' do
    post '/', create_message_json('http://ray-kbys.deviantart.com/art/Deep-Love-612306624')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("Deep Love by Ray-kbys on deviantART\nhttp://img02.deviantart.net/980e/i/2016/151/4/a/deep_love_by_ray_kbys-da4jutc.jpg")
  end

  it 'deviantART mature' do
    post '/', create_message_json('http://ray-kbys.deviantart.com/art/SweetRottenHalloween-409596429')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("[mature] SweetRottenHalloween!! by Ray-kbys on deviantART\nhttp://t06.deviantart.net/6VO3IdgukbyGNxPo-dOFKqvbdZE=/fit-in/150x150/filters:no_upscale():origin()/pre10/c2e4/th/pre/i/2013/299/3/f/sweetrottenhalloween___by_ray_kbys-d6rv2ml.jpg")
  end

  it 'multi URL' do
    post '/', create_message_json('https://nijie.info/view.php?id=175400 https://twitter.com/kumikumitm/status/693000092534587392')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("白スク水らぁらちゃん。 | momoi
https://pic04.nijie.info/small_light(dw=70)/nijie_picture/578583_20160625122416_0.png
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

  it '[]' do
    post '/', create_message_json('https://i.ytimg.com/vi/zADyHief9JE/maxresdefault.jpg?[1]=5')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("https://i.ytimg.com/vi/zADyHief9JE/maxresdefault.jpg?%5B1%5D=5")
  end

  it '[] with title' do
    post '/', create_message_json('https://www.youtube.com/watch?v=WWB01IuMvzA&[99]=aa')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("https://www.youtube.com/watch?v=WWB01IuMvzA&%5B99%5D=aa\nGod knows... ''The Melancholy of Haruhi Suzumiya'' 【涼宮ハルヒの憂鬱】　【Kadokawa公認MAD】 - YouTube")
  end

  it 'multibyte URL by domain' do
    post '/', create_message_json('https://湘南台商店連合会.com/')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("https://xn--6oq16hen6c15e441ar5zrr0d.com/\n藤沢市北部の湘南台商店連合会公式サイト")
  end

  it 'multibyte URL by domain and path' do
    post '/', create_message_json('https://湘南台商店連合会.com/news/日本の商店街では初めて？の日本語ドメイン利用/')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("https://xn--6oq16hen6c15e441ar5zrr0d.com/news/%E6%97%A5%E6%9C%AC%E3%81%AE%E5%95%86%E5%BA%97%E8%A1%97%E3%81%A7%E3%81%AF%E5%88%9D%E3%82%81%E3%81%A6%EF%BC%9F%E3%81%AE%E6%97%A5%E6%9C%AC%E8%AA%9E%E3%83%89%E3%83%A1%E3%82%A4%E3%83%B3%E5%88%A9%E7%94%A8/\n日本の商店街では初めて？の日本語ドメイン利用！ | 湘南台商店連合会公式サイト")
  end

  it 'multibyte URL' do
    post '/', create_message_json('https://ja.m.wikipedia.org/wiki/附属池田小事件')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("https://ja.m.wikipedia.org/wiki/%E9%99%84%E5%B1%9E%E6%B1%A0%E7%94%B0%E5%B0%8F%E4%BA%8B%E4%BB%B6\n附属池田小事件 - Wikipedia")
  end

  it 'multibyte domain and encoded path' do
    post '/', create_message_json('http://wiki.ポケモン.com/wiki/%E3%83%9D%E3%82%B1%E3%83%A2%E3%83%B3%E3%81%AE%E5%A4%96%E5%9B%BD%E8%AA%9E%E5%90%8D%E4%B8%80%E8%A6%A7')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("http://wiki.xn--rckteqa2e.com/wiki/%E3%83%9D%E3%82%B1%E3%83%A2%E3%83%B3%E3%81%AE%E5%A4%96%E5%9B%BD%E8%AA%9E%E5%90%8D%E4%B8%80%E8%A6%A7\nポケモンの外国語名一覧 - ポケモンWiki")
  end

  it 'Punycode domain and multibyte path' do
    post '/', create_message_json('http://wiki.xn--rckteqa2e.com/wiki/ポケモンの外国語名一覧')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("http://wiki.xn--rckteqa2e.com/wiki/%E3%83%9D%E3%82%B1%E3%83%A2%E3%83%B3%E3%81%AE%E5%A4%96%E5%9B%BD%E8%AA%9E%E5%90%8D%E4%B8%80%E8%A6%A7\nポケモンの外国語名一覧 - ポケモンWiki")
  end

  it 'multibyte domain and encoded path with []' do
    post '/', create_message_json('http://wiki.ポケモン.com/wiki/%E3%83%9D%E3%82%B1%E3%83%A2%E3%83%B3%E3%81%AE%E5%A4%96%E5%9B%BD%E8%AA%9E%E5%90%8D%E4%B8%80%E8%A6%A7?[0]')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("http://wiki.xn--rckteqa2e.com/wiki/%E3%83%9D%E3%82%B1%E3%83%A2%E3%83%B3%E3%81%AE%E5%A4%96%E5%9B%BD%E8%AA%9E%E5%90%8D%E4%B8%80%E8%A6%A7?%5B0%5D\nポケモンの外国語名一覧 - ポケモンWiki")
  end

  it 'Punycode domain and multibyte path with []' do
    post '/', create_message_json('http://wiki.xn--rckteqa2e.com/wiki/ポケモンの外国語名一覧?[0]')
    expect(last_response).to be_ok
    expect(last_response.body).to eq("http://wiki.xn--rckteqa2e.com/wiki/%E3%83%9D%E3%82%B1%E3%83%A2%E3%83%B3%E3%81%AE%E5%A4%96%E5%9B%BD%E8%AA%9E%E5%90%8D%E4%B8%80%E8%A6%A7?%5B0%5D\nポケモンの外国語名一覧 - ポケモンWiki")
  end

  describe 'unexplained bug in production' do
    it 'multibyte URL with hibiki' do
      post '/', create_message_json('http://dic.pixiv.net/a/紫京院ひびき')
      expect(last_response).to be_ok
      expect(last_response.body).to eq("http://dic.pixiv.net/a/%E7%B4%AB%E4%BA%AC%E9%99%A2%E3%81%B2%E3%81%B3%E3%81%8D\n紫京院ひびき (しきょういんひびき)とは【ピクシブ百科事典】")
    end

    it 'chichinai' do
      post '/', create_message_json('http://iris-soft.jp/chichinai/')
      expect(last_response).to be_ok
      expect(last_response.body).to eq("ちっちゃくないもんっ！〜スクールバスでおむかえちゅっちゅ〜特設サイト")
    end
  end
end
