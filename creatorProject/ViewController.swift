//
//  ViewController.swift
//  creatorProject
//
//  Created by GuantingLiu on 2019/10/27.
//  Copyright © 2019 GuantingLiu. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate,WKUIDelegate {

    @IBOutlet weak var transpLabel: UILabel!
    @IBOutlet weak var webV: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        transpLabel.backgroundColor = UIColor.init(red: 237/256, green: 237/256, blue: 238/256, alpha: 1)
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{ })
        
        webV.navigationDelegate = self
        webV.uiDelegate = self
        webV.customUserAgent = "Mozilla/5.0 (iPad; CPU OS 13_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.1 Mobile/15E148 Safari/604.1"
        webV.scrollView.setZoomScale(0.5, animated: false)
        webV.load(URLRequest(url: URL(string: "https://www.autodraw.com")!,cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10))
        
        print("aaa")
        
        
        
       
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print("bbb")
        print( #function + "url is \(String(describing: webView.url))"  + "Mimetype" + "\(navigationResponse.response.mimeType ?? "NotAvailable")")
        if let _ = navigationResponse.response.mimeType?.range(of: "audio/mpeg/png") {
            print("MP3 is audio url \(String(describing: webView.url))")
            webView.stopLoading()
        }
        decisionHandler(.allow)
    
    }
    


}

