//
//  ViewController.swift
//  Twinte
//
//  Created by tako on 2019/11/18.
//  Copyright © 2019 tako. All rights reserved.
//

import UIKit
import WebKit
import UserNotifications


class ViewController: UIViewController, WKUIDelegate,WKNavigationDelegate,WKScriptMessageHandler  {
    
    @IBOutlet var MainWebView: WKWebView!
    // 通知作成のためのクラス
    let Notification = ScheduleNotification()
    
    let myRequest = URLRequest(url: URL(string: "https://app.twinte.net")!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // アプリを起動するたびに通知を再設定する
        Notification.scheduleAllNotification()
        // これがないとjsのアラートが出ない
        MainWebView.uiDelegate = self
        // これがないとページを読み込んだ後の関数didFinish navigationが実行できない
        MainWebView.navigationDelegate = self
        // スクロール禁止
        MainWebView.scrollView.isScrollEnabled = false
        MainWebView.scrollView.panGestureRecognizer.isEnabled = false
        MainWebView.scrollView.bounces = false
        // プレビューを禁止する
        MainWebView.allowsLinkPreview = false
        
        // JSから呼び出される関数定義
        MainWebView.configuration.userContentController.add(self, name: "iPhoneSettings")
        MainWebView.configuration.userContentController.add(self, name: "share")
        // iPadはUserAgentがMacになるのでその対策
        if UIDevice.current.userInterfaceIdiom == .pad {
            // 使用デバイスがiPadの場合 UserAgentを固定
            MainWebView.customUserAgent = "Twin:teAppforiPad"
        }else if UIDevice.current.userInterfaceIdiom == .phone{
            MainWebView.customUserAgent = "Twin:teAppforiPhone"
        }
        // Cookieを保存
        MainWebView.configuration.websiteDataStore.httpCookieStore.getAllCookies() {(cookies) in
            var stringCookie:String = ""
            for eachcookie in cookies {
                if eachcookie.domain.contains(".twinte.net"){
                    stringCookie += "\(eachcookie.name)=\(eachcookie.value);"
                }
                // UserDefaults のインスタンス
                let userDefaults = UserDefaults(suiteName: "group.net.twinte.app")
                // AppGroupのUserDefaults に特定のドメインのCookieを保存（共有）
                userDefaults?.set(stringCookie,forKey: "stringCookie")
                userDefaults?.synchronize()
            }
            
        }
        
        MainWebView.load(myRequest)
        
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
    
    
    // WEBから呼び出される関数
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "share":
            share(body: message.body as! String)
        case "iPhoneSettings":
            self.performSegue(withIdentifier: "toSettings", sender: nil)
        default:
            break
        }
    }
    
    // WebViewのスクショを撮って返す
    // 参考：https://i.fukajun.net/iphone/capture-screen-of-wkwebview_swift3
    func getScreenShot()-> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.MainWebView.bounds.size, true, 0)
        self.MainWebView.drawHierarchy(in: self.MainWebView.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    // 時間割をシェアする
    func share(body:String) {
        // スクリーンショットを取得
        let shareImage = getScreenShot().pngData()
        // 共有項目
        let activityItems: [Any] = [shareImage!, body]
        // 初期化処理
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // iPad用処理
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityVC.popoverPresentationController?.sourceView = self.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        }
        
        // UIActivityViewControllerを表示
        self.present(activityVC, animated: true, completion: nil)
    }
    
    // リンク先のURLを格納
    var g_Url:URL?
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // app.twinte.netドメイン以外はサブWebViewで開く
        if let host : String = navigationAction.request.url?.host{
            // グローバル変数に格納
            g_Url = navigationAction.request.url
            if(host == "app.twinte.net" || host == "api.twinte.net" || host == "appleid.apple.com"){//この部分を処理したいURLにする
                decisionHandler(WKNavigationActionPolicy.allow)
            }else{
                self.performSegue(withIdentifier: "toSecond", sender: nil)
                decisionHandler(WKNavigationActionPolicy.cancel)
            }
        }
        
    }
    
    // 値を渡す
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        // toSecondに行くSegueを実行する時のみ処理
        if segue.identifier == "toSecond" {
            // 次の画面を取り出す
            let viewController = segue.destination as! SecondViewController
            // 値を渡す
            viewController.g_receviedUrl = g_Url
        }
    }
    
    //subWebViewから戻ってきたときはリロードする
    @IBAction func returnToMe(segue: UIStoryboardSegue) {
        MainWebView.reload()
    }
    func reload(){
        MainWebView.reload()
    }
    
}

