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
import MapKit
//import CoreLocation

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

extension Font {
    static func mainFont(size: CGFloat) -> Font {
        return Font.custom("rounded-mplus-1c-black", size: size)
    }
    
    static func subFont(size: CGFloat) -> Font {
        return Font.custom("rounded-mplus-1mn-bold", size: size)
    }
}

struct ContentView: View {
       
    @State private var user_id = 1
    @State private var sentence = ""
    
    // AI API
    @ObservedObject var ai_server = AnalyzeTextServer()
    @State private var editting = false
    @State private var showAlert = false
    @State private var res_delay = false
    @State private var isModal = false
    @State var showClearButton = true
    @State var debug_mode = false

    // MapView
    // 以下を追記
    @State var manager = CLLocationManager()
    @State var alert = false
    
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
                    .font(Font.mainFont(size: 28))
                    //.font(.custom("rounded-mplus-1c-black", size: 25))
            }
            .frame(width: 350, height: 50, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            ZStack {
                self.backGroundColor().edgesIgnoringSafeArea(.horizontal).foregroundColor(Color.white)
                VStack{
                    VStack{
                        TextField("発話文を入力して下さい", text: $sentence,
                                  
                            onEditingChanged: { begin in
                                if begin { /// 入力開始処理
                                    self.editting = true    // 編集フラグをオン
                                    self.showAlert = false // アラートメッセージは出さない
                                    self.res_delay = false //何秒か遅延して表示させる
                                } else {
                                    /// 入力終了処理
                                    self.editting = false   // 編集フラグをオフ
                                }
                            },
                            /// リターンキーが押された時の処理
                            onCommit: {
                                if sentence.isEmpty{
                                    self.showAlert = true //アラートを出す
                                    
                                } else {
                                    //self.showAlert = false // アラートメッセージは出さない
                                    self.ai_server.getData(user_id: self.user_id, sentence: self.sentence)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        print("レスポンス：\(self.ai_server.response)")
                                        print("レスポンス：\(self.ai_server.response_score)")
                                        print("レスポンス：\(self.ai_server.response_tokens)")
                                        self.res_delay = true // 入力文の色を変更
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.25) {
                                        if self.ai_server.response_code == 300 ||
                                            self.ai_server.response_code == 100 ||
                                            self.ai_server.response_code == 410 ||
                                            self.ai_server.response_code == 411 {
                                            isModal = true
                                        }
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
                                self.ai_server.response_tokens = []
                                self.ai_server.response_colors = []
                                if !self.speechRecorder.audioRunning {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    }
                                }
                                sentence = self.speechRecorder.audioText
                            }
                            else{
                                self.showingAlert = true
                            }
                        })
                        {
                            // 音声認識マイクボタン制御
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
                            //var tokens_list =
                            // マイクがONの時は音声認識のテキストを表示する。
                            // コンシェルジュのImageを謳歌すると再度UI Colorが呼ばれるため、呼ばれないようにしたい！課題！ --
                            if self.res_delay {
                                Group {
                                    // 音声認識の場合はそのままレコード内容を表示
                                    if self.speechRecorder.audioRunning {
                                        Text(self.speechRecorder.audioText)
                                    } else {
                                        // 音声認識でない場合は単語とそのアテンションスコアを表示
                                        // １６進数カラーコードが呼ばれないサーバ側の問題がある！
                                        HStack {
                                            ForEach(Array(zip(self.ai_server.response_tokens, self.ai_server.response_colors)), id: \.0) { item in
                                                    Text(item.0).foregroundColor(Color(UIColor(hex: item.1, alpha: 1)))
                                                }
                                        }
                                    }
                                }
                                .font(Font.subFont(size: 15))
                                .opacity(0.7)
                            } else {
                                Group {
                                    if self.speechRecorder.audioRunning {
                                        Text(self.speechRecorder.audioText)
                                    }
                                }
                                .foregroundColor(.white)
                                .font(Font.subFont(size: 15))
                                .opacity(0.7)
                            }
                        }.padding()
                    }
                }.padding()
            }
            HStack (alignment: .center){
                // デバッグモードのON/OFF
                Button(action:
                {
                    self.speechRecorder.audioText = ""
                    self.ai_server.response = ""
                    if self.debug_mode {
                        self.debug_mode = false
                    } else {
                        self.debug_mode = true
                    }
                })
                {
                    Image("ai_concierge")
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 100, height: 100, alignment: .leading)
                    Spacer()
                    //Text("羽田空港ですね\n承知いたしました。\nルート案内をしますので\n少々お待ちください")
                    //Text("羽田空港ですね承知いたしました。ルート案内をしますので少々お待ちください")
                    //Text("羽田空港ですね承知いたしました。\nルート案内をしますので\n少々お待ちください")
                    if self.res_delay {
                        Text(self.ai_server.response)
                            .frame(width: 250, height: 150)
                            //.font(.custom("rounded-mplus-1mn-bold", size: 15))
                            .font(Font.subFont(size: 16))
                            .foregroundColor(Color.black)
                        //self.ai_server.response = ""
                    }
                    

                }
            }
            .offset(x: -10, y: /*@START_MENU_TOKEN@*/10.0/*@END_MENU_TOKEN@*/)
            .frame(width: 380, height: 150)
            .sheet(isPresented: $isModal, onDismiss:{
                self.ai_server.response=""
                self.ai_server.response_tokens = []
                self.ai_server.response_colors = []
                })
                {
                    VStack {
                        Spacer()
                        Text("Maas Demo Maps")
                            .font(Font.mainFont(size: 20))
                        Spacer()
                        MaasView(manager: $manager, alert: $alert).alert(isPresented: $alert) {
                            Alert(title: Text("Please Enable Location Access In Setting Panel!!!"))
                        }
                    }
                }
            // デバッグ用の値を出力
            if self.debug_mode {
                HStack (alignment: .center){
                    Text("code : \(self.ai_server.response_code)")
                        .foregroundColor(.pink)
                        .font(Font.subFont(size: 12))
                        .opacity(0.5)
                    Text("prob : \(self.ai_server.response_score)")
                        .foregroundColor(.pink)
                        .font(Font.subFont(size: 12))
                        .opacity(0.5)
                }
            }
        }
        //.frame(width: 380, height: 350)
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
