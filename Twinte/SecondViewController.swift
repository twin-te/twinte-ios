//
//  SecondViewController.swift
//  Twinte
//
//  Created by tako on 2019/11/19.
//  Copyright © 2019 tako. All rights reserved.
//

import UIKit
import WebKit

// Twin:teにインポート機能用
struct TwinsLecture: Codable {
    let code, year: String
}

typealias TwinsLectures = [TwinsLecture]

class SecondViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    // WKScriptMessageHandlerプロトコル
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {}

    func alert(title: String, message: String) {
        DispatchQueue.main.async {
            // アラート生成
            // UIAlertControllerのスタイルがalert
            let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            // 確定ボタンの処理
            let confirmAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {
                // 確定ボタンが押された時の処理をクロージャ実装する
                (action: UIAlertAction!) in
                // 実際の処理

            })

            alert.addAction(confirmAction)

            // 実際にAlertを表示する
            self.present(alert, animated: true, completion: nil)
        }
    }

    // 画面推移の親から値を格納するグローバル変数
    var g_receviedUrl: URL?

    @IBOutlet var SubWebView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let myURL = g_receviedUrl
        //        let myURL = URL(string: "https://api.twinte.net")
        let myRequest = URLRequest(url: myURL!)

        // これがないとjsのアラートが出ない
        SubWebView.uiDelegate = self
        // これがないとページを読み込んだ後の関数didFinish navigationが実行できない
        SubWebView.navigationDelegate = self
        // バウンド禁止
        SubWebView.scrollView.bounces = false

        SubWebView.load(myRequest)

        // iOS13以降対応 プルダウンで閉じることを防ぐ
        // 参考:https://qiita.com/yimajo/items/7d329fa341d31476eb99
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        } else {
            // Fallback on earlier versions
        }
    }

    @IBAction func ExitButton(_ sender: Any) {}

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
        if TwinsWebView.title == "履修登録・登録状況照会 [CampusSquare]" || TwinsWebView.title == "CampusSquare for WEB [CampusSquare]" {
            // sp.jsのパスを取得
            guard let jsFilePath = Bundle.main.path(forResource: "sp", ofType: "js") else {
                // ファイルがない場合
                print("jsファイルがありません。")
                return
            }
            // javascriptを格納する
            let js: String
            // sp.jsの読み込み
            do {
                js = try String(contentsOfFile: jsFilePath, encoding: String.Encoding.utf8)
                TwinsWebView.evaluateJavaScript(js, completionHandler: nil)

            } catch {
                print("失敗しました。:\(error)")
                return
            }
        }

        // アクセスするapp.twinte.netドメインの時はサブWebViewを閉じる

        if let host: String = TwinsWebView.url?.host {
            if let absoluteURL = TwinsWebView.url?.absoluteString {
                if host == "app.twinte.net" { // この部分を処理したいURLにする
                    // 親のviewcontorollerを取得して関数を実行
                    let parentVC = self.presentingViewController as! ViewController
                    // アクセスしようとした画面をメインWebViewで開かせる
                    parentVC.afterLogin(url: absoluteURL)
                    // 自分を閉じる
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
}
