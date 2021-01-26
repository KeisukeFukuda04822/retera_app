//
//  AnalyzeServer.swift
//  TextSentenceAnalyze
//
//  Created by 福田佳祐 on 2021/01/26.
//

import Foundation

final class AnalyzeTextServer: ObservableObject {
    
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
