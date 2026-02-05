#順序は各セクターの順番に従う必要がある。

#1. 初期化
require "./OSC"
osc = OSC.new("127.0.0.1", 8000, 8001)
             #対象IPaddr , 送信, 受信ポート

#2. 受信イベント 受信処理を行わない場合は省略可能
#path: は省略可能だが、全ての値を受信するため注意。
osc.message(path: "/test/aba"){|event|
    puts event.data.path #-> /test
    puts event.data.type #-> bool, int, float, ?
    puts event.data      #-> true, 1234, 1.234
    if event.data==true
        osc.sendb("/test/boke", true) #-> Bool
    end
}

#3. 受信サーバー起動 2を省略した場合のみ省略可能
osc.run()

#4. その他処理/メインループ
osc.sendb("/test/hoge", true) #-> Bool
osc.sendi("/test/fuga", 123)  #-> Int
osc.sendf("/test/piyo", 1.23) #-> Float

loop{
	osc.sendi("/test/minute", Time.local.minute)
}