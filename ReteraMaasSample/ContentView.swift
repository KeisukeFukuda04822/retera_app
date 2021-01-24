//
//  ContentView.swift
//  ReteraMaasSample
//
//  Created by 福田佳祐 on 2020/12/20.
// Cmd + Option + Enter でビュー表示
// Cmd + / で一括コメントアウト

import SwiftUI
import Speech
import AVFoundation

extension UIColor {
    var color: Color {
        return Color(self)
    }

    convenience init(hex: String, alpha: CGFloat = 1.0) {
        //let string_ = string.replacingOccurrences(of: "#", with: "")
        let v = Int("000000" + hex, radix: 16) ?? 1
        let r = CGFloat(v / Int(powf(256, 2)) % 256) / 255
        let g = CGFloat(v / Int(powf(256, 1)) % 256) / 255
        let b = CGFloat(v / Int(powf(256, 0)) % 256) / 255
        print(r, g, b)
        self.init(red: r, green: g, blue: b, alpha: min(max(alpha, 0), 1))
    }
}

//extension UIColor {
//    var color: Color {
//        return Color(self)
//    }
//
//    class func hex ( string : String, alpha : CGFloat) -> UIColor {
//        let string_ = string.replacingOccurrences(of: "#", with: "")
//        let scanner = Scanner(string: string_ as String)
//        var color: UInt64 = 0
//        if scanner.scanHexInt64(&color) {
//            let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
//            let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
//            let b = CGFloat(color & 0x0000FF) / 255.0
//            print(r,g,b)
//            return UIColor(red:r,green:g,blue:b,alpha:alpha)
//        } else {
//            return UIColor.white;
//        }
//    }
//}

class aiServer: ObservableObject {
    
    private let url = URL(string: "http://100.64.1.16:30000/")
    @Published var user_id: Int
    @Published var sentence: String
    @Published var response : String
    @Published var response_code : Int
    @Published var response_score : Float
    @Published var response_tokens : Array<String>
    @Published var response_colors : Array<String>
    
    
    init(){
        print("call API")
        self.user_id = 0
        self.sentence = ""
        self.response = ""
        self.response_code = 0
        self.response_score = 0.00
        self.response_tokens = []
        self.response_colors = []
        getData(user_id : self.user_id, sentence : self.sentence)
    }
    
    func getData(user_id: Int, sentence: String) {
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
                        print("get Json: \(getJson)")
                        DispatchQueue.main.async{ // responseを非同期にする
                            self.response = (getJson["response"] as? String)!
                            self.response_code = (getJson["res_code"] as? Int)!
                            if let res_score = getJson.value(forKey: "res_score") as? NSNumber {
                                self.response_score = res_score.floatValue
                            } else {
                                self.response_score = (getJson["res_score"] as? Float)!
                            }
                            self.response_tokens = (getJson["tokens"] as? Array)!
                            self.response_colors = (getJson["token_colors"] as? Array)!
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



struct ContentView: View {
       
    @State private var user_id = 1
    @State private var sentence = ""
    
    // AI API
    @ObservedObject var ai_server = aiServer()
    //@State private var response = ""
    //@State private var response_code : Int = 0
    //@State private var response_score : Float = 0.00
    //@State private var tokens_list = [[]]
    @State private var editting = false
    @State private var showAlert = false
    @State private var changeColor = false
    @State var showClearButton = true
    
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
                                    self.showAlert = false // アラートメッセージは出さない
                                    self.changeColor = false
                                    //self.response = ""       // メッセージをクリア
                                    //self.response_code = 0       // メッセージをクリア
                                    //self.response_score = 0.00       // メッセージをクリア
                                    
                                    /// 入力終了処理
                                } else {
                                    self.editting = false   // 編集フラグをオフ
                                }
                            },
                            /// リターンキーが押された時の処理
                            onCommit: {
                                if sentence.isEmpty{
                                    self.showAlert = true //アラートを出す
                                    
                                } else {
                                    //self.showAlert = false // アラートメッセージは出さない
                                    self.changeColor = true // 入力文の色を変更
                                    self.ai_server.getData(user_id: self.user_id, sentence: self.sentence)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        print("レスポンス：\(self.ai_server.response)")
                                        print("レスポンス：\(self.ai_server.response_score)")
                                    }
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
                            Group {
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
                        }
                        .alert(isPresented: $showingAlert) {
                            Alert(title: Text("マイクの使用または音声の認識が許可されていません"))
                        }
                        
                        // 入力した文章の表示
                        VStack(alignment: .center){
                            //var tokens_list =
                            // マイクがONの時は音声認識のテキストを表示する。
                            if self.changeColor {
                                Group {
                                    // 音声認識の場合はそのままレコード内容を表示
                                    if self.speechRecorder.audioRunning {
                                        Text(self.speechRecorder.audioText)
                                    } else {
                                        // 音声認識でない場合は単語とそのアテンションスコアを表示
                                        HStack {
                                            ForEach(Array(zip(self.ai_server.response_tokens, self.ai_server.response_colors)), id: \.0) { item in
                                                    Text(item.0).foregroundColor(Color(UIColor(hex: item.1, alpha: 1)))
                                                }
                                        }
                                    }
                                }
                                //.foregroundColor(.black)
                                //.foregroundColor(Color(UIColor.hex(string: "#FF9A9A", alpha: 1)))
                                .font(.custom("rounded-mplus-1mn-bold", size: 18))
                                .opacity(0.7)
                            } else {
                                Group {
                                    if self.speechRecorder.audioRunning {
                                        Text(self.speechRecorder.audioText)
                                    } else {
                                        Text(self.sentence)
                                    }
                                }
                                .foregroundColor(.white)
                                //.foregroundColor(UIColor.hex(string: "#ffffff", alpha: 1))
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
                //Text(response)
                Text(self.ai_server.response)
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
                Text("code : \(self.ai_server.response_code)")
                    .foregroundColor(.pink)
                    .font(.custom("rounded-mplus-1mn-bold", size: 12))
                    .opacity(0.5)
                Text("prob : \(self.ai_server.response_score)")
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
