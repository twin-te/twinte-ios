//
//  ViewController.swift
//  Twinte
//
//  Created by tako on 2019/11/18.
//  Copyright © 2019 tako. All rights reserved.
//

import UIKit
import WebKit

struct Lecture: Codable {
    let period: Int
    let room: String
    let lecture_name: String
    let instructor: String
}

class ViewController: UIViewController, WKUIDelegate,WKNavigationDelegate  {
    
    @IBOutlet var MainWebView: WKWebView!
    
    let myRequest = URLRequest(url: URL(string: "https://app.twinte.net")!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // キャッシュ消去
        // WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: 0), completionHandler: {})
        // バージョンが変更されたときに反映されなくなってしまうためきCokkie以外消去
        //WKWebsiteDataStore.default().removeData(ofTypes: [WKWebsiteDataTypeDiskCache], modifiedSince: Date(timeIntervalSince1970: 0), completionHandler: {})
        
        // これがないとjsのアラートが出ない
        MainWebView.uiDelegate = self
        // これがないとページを読み込んだ後の関数didFinish navigationが実行できない
        MainWebView.navigationDelegate = self
        
        // スクロール禁止
        MainWebView.scrollView.isScrollEnabled = false;
        MainWebView.scrollView.panGestureRecognizer.isEnabled = false;
        MainWebView.scrollView.bounces = false;
        
        // iPadはUserAgentがMacになるのでその対策
        if UIDevice.current.userInterfaceIdiom == .pad {
            // 使用デバイスがiPadの場合 UserAgentを固定
            MainWebView.customUserAgent = "Twin:teAppforiPad"
        }else if UIDevice.current.userInterfaceIdiom == .phone{
            MainWebView.customUserAgent = "Twin:teAppforiPhone"
        }
        
        MainWebView.load(myRequest)
        
        MainWebView.configuration.websiteDataStore.httpCookieStore.getAllCookies() {(cookies) in
            var stringCookie:String = ""
            for eachcookie in cookies {
                if eachcookie.domain.contains(".twinte.net"){
                    stringCookie += "\(eachcookie.name)=\(eachcookie.value);"
                }
            }
            // UserDefaults のインスタンス
            let userDefaults = UserDefaults.standard
            // UserDefaults に特定のドメインのCookieを保存
            userDefaults.set(stringCookie,forKey: "stringCookie")
            userDefaults.synchronize()
            
        }
        // 今日の時間割を取得する関数
        let date:String = "2019-12-12"
        todayget(date: date)
    }
    
    
    func todayget(date: String){
        let requestUrl = "https://dev.api.twinte.net/v1/timetables/?date="+date
        
        // URL生成
        guard let url = URL(string: requestUrl) else {
            // URL生成失敗
            return
        }
        
        // リクエスト生成
        var request = URLRequest(url: url)
        // UserDefaults のインスタンス
        let userDefaults = UserDefaults.standard
        if let stringCookie = userDefaults.string(forKey: "stringCookie"){
            // UserDefaultsからCookieを取得
            request.setValue(stringCookie, forHTTPHeaderField: "Cookie")
        }
        // 商品検索APIをコールして商品検索を行う
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data:Data?,
            response:URLResponse?, error:Error?) in
            // 通信完了後の処理
            // エラーチェック
            guard error == nil else {
                // エラー表示
                let alert = UIAlertController(title: "エラー",
                                              message: error?.localizedDescription,
                                              preferredStyle: UIAlertController.Style.alert)
                print(alert)
                return
            }
            
            // JSONで返却されたデータをパースして格納する
            guard let data = data else {
                // データなし
                return
            }
            /*
             let str = String(decoding: data, as: UTF8.self)
             print(str)
             // jsonをそのまま表示
             
             do {
             let object = try JSONSerialization.jsonObject(with: data, options: [])
             print(object)
             } catch let e {
             print(e)
             }
             */
            do {
                // パース実施
                let resultSet = try JSONDecoder().decode([Lecture].self, from: data)
                print(resultSet)
            } catch let error {
                print("## error: \(error)")
            }
        }
        // 通信開始
        task.resume()
    }
    
    
    // JSのアラートをネイティブて扱う
    // 参考：https://qiita.com/furu8ma/items/183f85a106ba827ad0ea
    // alertを表示する
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        let alertController =
            UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        let okAction =
            UIAlertAction(title: "OK", style: .default) { action in
                completionHandler()
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // confirm dialogを表示する
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        let alertController =
            UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        let cancelAction =
            UIAlertAction(title: "Cancel", style: .cancel) { action in
                completionHandler(false)
        }
        
        let okAction =
            UIAlertAction(title: "OK", style: .default) {
                action in completionHandler(true)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // リンク先のURLを格納
    var g_Url:URL?
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // app.twinte.netドメイン以外はサブWebViewで開く
        if let host : String = navigationAction.request.url?.host{
            // グローバル変数に格納
            g_Url = navigationAction.request.url
            if(host == "app.twinte.net" || host == "dev.api.twinte.net" || host == "appleid.apple.com"){//この部分を処理したいURLにする
                decisionHandler(WKNavigationActionPolicy.allow)
            }else{
                self.performSegue(withIdentifier: "toSecond", sender: nil)
                decisionHandler(WKNavigationActionPolicy.cancel)
            }
        }
        
    }
    
    // 値を渡す
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        // 次の画面を取り出す
        let viewController = segue.destination as! SecondViewController
        // 値を渡す
        viewController.g_receviedUrl = g_Url
        
    }
    //subWebViewから戻ってきたときはリロードする
    @IBAction func returnToMe(segue: UIStoryboardSegue) {
        MainWebView.reload()
    }
    func reload(){
        MainWebView.reload()
    }
    
}

