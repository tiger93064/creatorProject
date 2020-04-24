//
//  ViewController.swift
//  creatorProject
//
//  Created by GuantingLiu on 2019/10/27.
//  Copyright © 2019 GuantingLiu. All rights reserved.
//

import UIKit
import WebKit
 

class ViewController: UIViewController, WKNavigationDelegate,WKUIDelegate{

    @IBOutlet weak var transpLabel: UILabel!
    @IBOutlet weak var transLabel1: UILabel!
    @IBOutlet weak var webV: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationController?.setNavigationBarHidden(true, animated:true)                                          //hide navigationBar
        
        transpLabel.backgroundColor = UIColor.init(red: 237/256, green: 237/256, blue: 238/256, alpha: 0)          //make a hidder for web's burgerBar with certain color.
        transLabel1.backgroundColor = UIColor.init(red: 237/256, green: 237/256, blue: 238/256, alpha: 1) 
        
        webV.navigationDelegate = self                                                                             //initiate WKWebview
        webV.uiDelegate = self
        webV.customUserAgent = "Mozilla/5.0 (iPad; CPU OS 13_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.1 Mobile/15E148 Safari/604.1"
                webV.load(URLRequest(url: URL(string: "https://www.autodraw.com")!,cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10))
        
        
       
    }
    
    //to specifie the web that going is  which kind of extansion name.
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print("bbb")
        print( #function + "url is \(String(describing: webView.url))"  + "Mimetype" + "\(navigationResponse.response.mimeType ?? "NotAvailable")")
        if let _ = navigationResponse.response.mimeType?.range(of: "audio/mpeg/png") {
            print("MP3 is audio url \(String(describing: webView.url))")
            webView.stopLoading()
        }
        decisionHandler(.allow)
    }
    
    //press done button
    @IBAction func btnDone(_ sender: Any) {
        let config = WKSnapshotConfiguration()                                              //take snapshot of wkwebview with a rect
        config.rect = CGRect(x: 67.5, y: 82.0, width: 845, height: 690)
        webV.takeSnapshot(with: config, completionHandler: {image, error in
            if let image = image {
                print(image)
                print("Got snapshot")                                                       //initiate editing page and set img to its image property
                if let editingP = self.storyboard?.instantiateViewController(identifier: "editingPage") as? editingPageViewController{
                    //editingP.dismiss(animated: false, completion: nil)
                    editingP.img = image
                    self.navigationController?.pushViewController(editingP, animated: true) //go editing page
                }
            }
            else {
                print("Failed taking snapshot: \(error?.localizedDescription ?? "--")")
            }

        })
        
        
        
    }
    
    //whenever go back to this view, hide navigationBar
    override func viewDidAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated:true)
    }
    
}

