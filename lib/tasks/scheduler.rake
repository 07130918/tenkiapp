desc "This task is called by the Heroku scheduler add-on"
task :update_feed => :environment do
    require 'line/bot'  # linebot-api導入
    require 'open-uri'
    require 'kconv'
    require 'rexml/document'
    # linebot側の設定,herokuのキー挿入
    client ||= Line::Bot::Client.new { |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
    # xmlデータ
    url  = "https://www.drk7.jp/weather/xml/13.xml"
    xml = open( url ).read.toutf8
    doc = REXML::Document.new(xml)
    # area[4]はareaタグの4番目にいる東京地方を指している
    xpath = 'weatherforecast/pref/area[4]/info/rainfallchance/'
    # それぞれの時間の降水確率
    per06to12 = doc.elements[xpath + 'period[2]'].text
    per12to18 = doc.elements[xpath + 'period[3]'].text
    per18to24 = doc.elements[xpath + 'period[4]'].text
    
    min_per = 20 #降水確率20％以上でメッセージを送信
    if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
        # 配列からランダムで要素を返す引数がない場合1つ?
        word1 = ["おはよう！", "Good Morning", "早安", "Bonjour.", "Guten Morgen!", "Buenos Dias！", "Buongiorno", "Bom dia.", "Goede morgen.", "Gunaydin.", " God morogon."].sample
        word2 = ["良い１日を!", "Have a goood day!", "締まっていこう!", "水を飲もう", "夜はビールを飲もう!", "カフェに行こう", "朝活の鬼になろう!", "午前中の生産性に命を捧げよ"].sample
        
    mid_per = 50 #降水確率が50%以上の時
        if per06to12.to_i >= mid_per || per12to18.to_i >= mid_per || per18to24.to_i >= mid_per
            word3 = "１雨来るぜこれは\r\nDon't forget your umbrella because it's going to rain today!"
        else  #降水確率が20％～50％未満の時
            word3 = "傘があると良いかもね\r\nスマホが水没したら俺の人生が終わる\r\nIt might rain today, so it's safe to have a folding umbrella!"
        end    
    
    push = "#{word1}\r\n#{word3}\r\n降水確率はこんな感じ\r\n 6〜12時 #{per06to12}％\r\n 12〜18時 #{per12to18}％\r\n 18〜24時 #{per18to24}％\r\n#{word2}"
    # userモデルを介しline_idカラムの値全てを取り出す     
    user_ids = User.all.pluck(:line_id)
    message = {
      type: 'text',
      text: push
    }
    response = client.multicast(user_ids, message)
    end    
   "OK" 
end
