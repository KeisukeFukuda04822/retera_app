//
//  ContentView.swift
//  ReteraMaasSample
//
//  Created by 福田佳祐 on 2020/12/20.
// Cmd + Alt + Enter でビュー表示
// Cmd + / で一括コメントアウト

import SwiftUI

struct ContentView: View {
   
    @State private var sentence = ""
    @State private var response = ""
    //@State private var res_title = ""
    @State private var editting = false
    let url = URL(string: "http://100.64.1.16:30000/")
       
    var body: some View {
        VStack {
            VStack{
                Text("リテラ対話デモツール")
                    .fontWeight(.medium)
                    .font(.custom("rounded-mplus-1c-black", size: 25))
            }
            ZStack {
                Spacer()
                //self.backGroundColor().edgesIgnoringSafeArea(.horizontal).foregroundColor(Color.white)
                //let backGroundColor = LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]), startPoint: .top, endPoint: .bottom)
                self.backGroundColor().edgesIgnoringSafeArea(.all)
                TextField("発話文を入力して下さい", text: $sentence,
                          
                    onEditingChanged: { begin in
                        /// 入力開始処理
                        if begin {
                            self.editting = true    // 編集フラグをオン
                            self.sentence = ""       // メッセージをクリア
                            //self.res_title = ""       // メッセージをクリア
                                
                            /// 入力終了処理
                        } else {
                            self.editting = false   // 編集フラグをオフ
                        }
                    },

                    /// リターンキーが押された時の処理
                    onCommit: {
                        //self.sentence = ""  // 入力域をクリア
                        let return_json = "{\"text\":\"\(self.sentence)\"}".data(using: .utf8)
                        // POSTを指定
                        var request = URLRequest(url: url!)
                        request.httpMethod = "POST"
                        // POSTするデータをBodyとして設定
                        request.httpBody = "os=iOS&version=11&language=日本語".data(using: .utf8)
                        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.httpBody = return_json
                        
                        // 新しくURLSessionインスタンスを作成
                        //let session = URLSession(configuration: config)
                        URLSession.shared.dataTask(with: request) { (data, response, error) in
                            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                                // HTTPヘッダの取得
                                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                                // HTTPステータスコード
                                print("statusCode: \(response.statusCode)")
                                
                                if case 200..<300 = response.statusCode {
                                    print("success")
                                    print(String(data: data, encoding: .utf8) ?? "")
                                    //var response_json = String(data: data, encoding: .utf8) ?? ""
                                    //self.response = response_json.getForKey("response") as! String // mode="easy"
                                    // 受け取ったdataをJSONパース、エラーならcatchへジャンプ
                                    
                                    do {
                                        // dataをJSONパースし、変数"getJson"に格納
                                        let getJson = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary

                                        //self.response = (getJson["response"] as? String)!
                                        // respponseを非同期にする
                                        DispatchQueue.main.async{
                                            self.response = (getJson["response"] as? String)!
                                            print("finish")
                                            //self.res_title = " -- 応答 --"
                                        }
                                        
                                    } catch {
                                        print ("JsonParseError")
                                        return
                                    }
                                } else {
                                    print("API request Error!")
                                    self.response = "すみません、よく分かりません。"
                                }
                                
                            }
                        }.resume()
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle()) // 入力域を枠で囲む
                    .padding()      // 余白を追加
                    // 編集フラグがONの時に枠に影を付ける
                    .shadow(color: editting ? .blue : .clear, radius: 3)
            }
            HStack (alignment: .center){
                Image("ai_concierge")
                    .resizable()
                    .clipShape(Circle())
                    .frame(width: 120, height: 120, alignment: .leading)
                Text(response)
                    .font(.custom("rounded-mplus-1mn-bold", size: 15))
                    // 枠線を描画
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.orange, lineWidth: 0.25)
                    )
                Spacer()
            }
            .padding()      // 余白を追加
        }
    }
    /// 背景グラデーションを作成する
    private func backGroundColor() -> LinearGradient {
        // 左上から右下にポイントを設定する。
        //let start = UnitPoint.init(x: 0, y: 0) // 左上(始点)
        //let end = UnitPoint.init(x: 1, y: 1) // 右下(終点)
        // 「Color」は以前の「UIColor」からの変換もできるぞ！ 助かる。
        //let colors = Gradient(colors: [Color(UIColor.blue), Color(UIColor.green), Color(UIColor.purple), Color(UIColor.green), Color(UIColor.green)])
        //let gradientColor = LinearGradient(gradient: colors, startPoint: start, endPoint: end)
        let gradientColor = LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]), startPoint: .top, endPoint: .bottom)

        return gradientColor
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
