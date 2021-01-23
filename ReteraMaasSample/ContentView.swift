//
//  ContentView.swift
//  ReteraMaasSample
//
//  Created by 福田佳祐 on 2020/12/20.
// Cmd + Option + Enter でビュー表示
// Cmd + / で一括コメントアウト

import SwiftUI
import SwiftUICharts
import Speech
import AVFoundation

struct ContentView: View {
   
    // AI API
    @State private var user_id = 1
    @State private var sentence = ""
    @State private var response = ""
    @State private var sentence_pass : Array<String> = []
    @State private var response_code : Int = 0
    @State private var response_score : Float = 0.00
    @State private var editting = false
    @State private var showAlert = false
    
    @State var showClearButton = true
    
    let url = URL(string: "http://100.64.1.16:30000/")
    
    // 音声認識  変数
    @ObservedObject private var speechRecorder = SpeechRecorder()
    @State var showingAlert = false
    
    /// 背景グラデーションを作成する
    private func backGroundColor() -> LinearGradient {
        let gradientColor = LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]), startPoint: .top, endPoint: .bottom)
        return gradientColor
    }

    
    var body: some View {
        VStack {
            VStack{
                Text("リテラ対話デモツール")
                    .fontWeight(.medium)
                    .font(.custom("rounded-mplus-1c-black", size: 25))
            }
            ZStack {
                self.backGroundColor().edgesIgnoringSafeArea(.horizontal).foregroundColor(Color.white)
                VStack{
                    VStack{
                        TextField("発話文を入力して下さい", text: $sentence,
                                  
                            onEditingChanged: { begin in
                                if begin { /// 入力開始処理
                                    self.editting = true    // 編集フラグをオン
                                    //self.response = ""       // メッセージをクリア
                                    self.response_code = 0       // メッセージをクリア
                                    self.response_score = 0.00       // メッセージをクリア
                                    
                                    /// 入力終了処理
                                } else {
                                    self.editting = false   // 編集フラグをオフ
                                }
                            },
                            /// リターンキーが押された時の処理
                            onCommit: {
                                if sentence.isEmpty{
                                    showAlert = true
                                    
                                } else {
                                    showAlert = false
                                    var url_request = URLRequest(url: url!)
                                    let request_json = "{\"user_id\":\"\(user_id)\", \"text\":\"\(sentence)\"}".data(using: .utf8)
                                    //print(request_json)
                                    url_request.httpMethod = "POST"
                                    url_request.httpBody = "os=iOS&version=11&language=日本語".data(using: .utf8)
                                    url_request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                                    url_request.httpBody = request_json
                                    let task = URLSession.shared.dataTask(with: url_request) { (data, response, error) in
                                        if error == nil, let data = data, let response = response as? HTTPURLResponse {
                                            print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")") // HTTPヘッダの取得
                                            print("statusCode: \(response.statusCode)") // HTTPステータスコード

                                            if case 200..<300 = response.statusCode {
                                                print("success")
                                                print(String(data: data, encoding: .utf8) ?? "")
                                                do {  // 受け取ったdataをJSONパース、エラーならcatchへジャンプ
                                                    // dataをJSONパースし、変数"getJson"に格納
                                                    let getJson = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                                                    print(getJson)
                                                    DispatchQueue.main.async{ // responseを非同期にする
                                                        self.response = (getJson["response"] as? String)!
                                                        self.response_code = (getJson["res_code"] as? Int)!
                                                        if let res_score = getJson.value(forKey: "res_score") as? NSNumber {
                                                            self.response_score = res_score.floatValue
                                                        } else {
                                                            self.response_score = (getJson["res_score"] as? Float)!
                                                        }
                                                        self.sentence_pass = (getJson["sentence_pass"] as? Array)!
//                                                        for cat in self.sentence_pass {
//                                                              print("name:\(cat)")
//                                                        }
                                                    }
                                                } catch {
                                                    print ("JsonParseError")
                                                    return
                                                }
                                            } else if case 500 = response.statusCode {
                                                print("API Program Error!")
                                                self.response = "すみません。\nサーバ側で問題が発生しているようです。"
                                            } else {
                                                print("API request Error!")
                                                self.response = "すみません。\nサーバ側でレスポンス200以外を返しているようです。"
                                            }
                                        } else {
                                            print("API Connection Error!")
                                            self.response = "すみません。\nサーバとの接続がうまくできていないようです。"
                                        }
                                    }
                                    task.resume()
                                }
                            }
                        )
                        .alert(isPresented: $showAlert) {
                             Alert(title: Text("発話文を入力してください"),
                                             message: Text(""),
                                             dismissButton: .destructive(Text("閉じる")))
                        }
                        .modifier(ClearButton(text: $sentence, visible: $showClearButton))
                        .multilineTextAlignment(.leading)
                        .textFieldStyle(RoundedBorderTextFieldStyle()) // 入力域を枠で囲む
                        .padding()      // 余白を追加
                        .shadow(color: editting ? .blue : .clear, radius: 5) // 編集フラグがONの時に枠に影を付ける
                        
                        // マイクボタン
                        Button(action: {
                            if(AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) == .authorized &&
                                SFSpeechRecognizer.authorizationStatus() == .authorized){
                                self.showingAlert = false
                                self.speechRecorder.toggleRecording()
                                if !self.speechRecorder.audioRunning {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {

                                    }
                                }
                                sentence = self.speechRecorder.audioText
                            }
                            else{
                                self.showingAlert = true
                            }
                        })
                        {
                            if !self.speechRecorder.audioRunning {
                                Image(systemName: "mic")
                                    .resizable()
                                    .frame(width: 20, height: 20, alignment: .center)
                                    .clipShape(Circle())
                                    .foregroundColor(.white)
                                    .padding()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 30)
                                            .stroke(Color.white, lineWidth: 2))
                            } else {
                                Image(systemName: "mic")
                                    .resizable()
                                    .frame(width: 20, height: 20, alignment: .center)
                                    .clipShape(Circle())
                                    .foregroundColor(.white)
                                    .padding()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 30)
                                            .stroke(Color.white.opacity(0.6), lineWidth: 2))
                                    .opacity(0.3)
                            }
                        }
                        .alert(isPresented: $showingAlert) {
                            Alert(title: Text("マイクの使用または音声の認識が許可されていません"))
                        }
                        
                        // 入力した文章の表示
                        VStack(alignment: .center){
                            // マイクがONの時は音声認識のテキストを表示する。
                            if self.speechRecorder.audioRunning {
                                Text(self.speechRecorder.audioText)
                                    .foregroundColor(.white)
                                    .font(.custom("rounded-mplus-1mn-bold", size: 16))
                                    .opacity(0.7)
                            }
                        }.padding()
                    }
                }.padding()
            }
            HStack (alignment: .center){
                Image("ai_concierge")
                    .resizable()
                    .clipShape(Circle())
                    .frame(width: 100, height: 100, alignment: .leading)
                    .padding(.trailing, 1)
                Spacer()
                //Text("羽田空港ですね\n承知いたしました。\nルート案内をしますので\n少々お待ちください")
                //Text("羽田空港ですね承知いたしました。ルート案内をしますので少々お待ちください")
                //Text("羽田空港ですね承知いたしました。\nルート案内をしますので\n少々お待ちください")
                Text(response)
                    .frame(width: 250, height: 150)
                    .font(.custom("rounded-mplus-1mn-bold", size: 15))
                    .foregroundColor(Color.black)
                Spacer()
            }
//            ZStack {
//                HStack (alignment: .center){
//                    Image("ai_concierge")
//                        .resizable()
//                        .clipShape(Circle())
//                        .frame(width: 100, height: 100, alignment: .leading)
//                        .padding(.trailing, 1)
//                    Rectangle().foregroundColor(Color.white)
//                        .cornerRadius(15.0)
//                    Rectangle().foregroundColor(Color.black.opacity(0.8))
//                        .frame(width: 272, height: 142)
//                        .cornerRadius(15.0)
//                    Spacer()
//                    Text(response).frame(width: 310, height: 150)
//                    //Text("羽田空港ですね\n承知いたしました。\nルート案内をしますので\n少々お待ちください")
//                    //Text("羽田空港ですね承知いたしました。ルート案内をしますので少々お待ちください")
//                    //Text("羽田空港ですね承知いたしました。\nルート案内をしますので\n少々お待ちください")
//                        .font(.custom("rounded-mplus-1mn-bold", size: 15))
//                        .foregroundColor(Color.black)
//                        .padding(.leading, -55)
//                        .padding(.top, 1)
//                    Spacer()
//                }
//                .frame(width:370, height: 150)
//            }
            HStack (alignment: .center){
                Text("num : \(response_code)")
                    .foregroundColor(.pink)
                    .font(.custom("rounded-mplus-1mn-bold", size: 12))
                    .opacity(0.5)
                Text("prob : \(response_score)")
                    .foregroundColor(.pink)
                    .font(.custom("rounded-mplus-1mn-bold", size: 12))
                    .opacity(0.5)
            }
            .onAppear{
                AVCaptureDevice.requestAccess(for: AVMediaType.audio) { granted in
                    OperationQueue.main.addOperation {

                    }
                }
                SFSpeechRecognizer.requestAuthorization { status in
                    OperationQueue.main.addOperation {
                    }
                }
            }
            .padding()
        }
    }
}

struct ClearButton: ViewModifier {
    @Binding var text: String
    @Binding var visible: Bool
    public func body(content: Content) -> some View {
        HStack {
            content
            Image(systemName: "multiply.circle.fill")
                .foregroundColor(.secondary)
                .opacity(visible ? 1 : 0)
                .onTapGesture {
                    self.text = ""
                }
            // ButtonのActionでも機能としては実現できるが、クリアボタン以外の部分もハイライトされてしまう。
//            Button(action: {
//                self.text = ""
//            }) {
//                Image(systemName: "multiply.circle.fill")
//                    .foregroundColor(.secondary)
//                    .opacity(visible ? 1 : 0)
//            }
        }
    }
}

//struct ClearButton: ViewModifier
//{
//    @Binding var text: String
//
//    public func body(content: Content) -> some View
//    {
//        ZStack(alignment: .trailing)
//        {
//            content
//            if !text.isEmpty
//            {
//                Button(action:
//                {
//                    self.text = ""
//                })
//                {
//                    Image(systemName: "delete.left")
//                        .foregroundColor(Color(UIColor.opaqueSeparator))
//                }
//                .padding(.trailing, 8)
//            }
//        }
//    }
//}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
