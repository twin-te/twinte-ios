//
//  ViewController.swift
//  Twinte
//
//  Created by tako on 2019/11/18.
//  Copyright © 2019 tako. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKUIDelegate,WKNavigationDelegate  {
    
    @IBOutlet var MainWebView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // キャッシュ消去
        // WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: 0), completionHandler: {})
        let myURL = URL(string: "https://app.twinte.net")
        let myRequest = URLRequest(url: myURL!)
        // これがないとjsのアラートが出ない
        MainWebView.uiDelegate = self
        // これがないとページを読み込んだ後の関数didFinish navigationが実行できない
        MainWebView.navigationDelegate = self
        
        // スクロール禁止
        MainWebView.scrollView.isScrollEnabled = false;
        MainWebView.scrollView.panGestureRecognizer.isEnabled = false;
        MainWebView.scrollView.bounces = false;
        
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
    
    // Twinsの履修画面でJSを挿入
    func webView(_ TwinsWebView: WKWebView, didFinish navigation: WKNavigation!) {
        // ページのタイトルが履修登録ページのものだった場合に実行
        if TwinsWebView.title == "履修登録・登録状況照会 [CampusSquare]"{
            // sp.jsのパスを取得
            guard let jsFilePath = Bundle.main.path(forResource: "sp", ofType: "js") else{
                // ファイルがない場合
                print("jsファイルがありません。")
                return
            }
            // javascriptを格納する
            let js:String
            // sp.jsの読み込み
            do{
                js = try String(contentsOfFile: jsFilePath, encoding: String.Encoding.utf8)
                TwinsWebView.evaluateJavaScript(js, completionHandler: nil)
            }catch let error{
                print ("失敗しました。:\(error)")
                return
            }
            
        }
    }
    
}

