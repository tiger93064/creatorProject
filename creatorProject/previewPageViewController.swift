//
//  previewPageViewController.swift
//  creatorProject
//
//  Created by GuantingLiu on 2019/11/17.
//  Copyright © 2019 GuantingLiu. All rights reserved.
//

import UIKit

class previewPageViewController: UIViewController, UIDocumentInteractionControllerDelegate{

    @IBOutlet weak var previewImgV: UIImageView!
    var OKimg:UIImage?
    var savePath:URL?
    
    let dICon = UIDocumentInteractionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(self.saveImage(image: OKimg!))
        previewImgV.image = getImage(named: "OKimg.png")
        // Do any additional setup after loading the view.
        
        dICon.delegate = self
        
        
        
    }
    
    func saveImage(image: UIImage) -> Bool {
        guard let data = image.pngData() else {
            return false
        }
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return false
        }
        do{
            try data.write(to: directory.appendingPathComponent("OKimg.png")!)
            savePath = directory.appendingPathComponent("OKimg.png")!
            return true
        }
        catch{
            print(error.localizedDescription)
            return false
        }
    }
    func getImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    func share(url: URL) {
        dICon.url = url
        dICon.uti = url.typeIdentifier ?? "public.data, public.content"
        dICon.name = url.localizedName ?? url.lastPathComponent
        dICon.presentPreview(animated: true)
    }
    
    /// This function will store your document to some temporary URL and then provide sharing, copying, printing, saving options to the user
    func storeAndShare(withURL: URL) {
    
        DispatchQueue.main.async {
            /// STOP YOUR ACTIVITY INDICATOR HERE
            self.share(url: withURL)
        }
            
    }
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        guard let navVC = self.navigationController else {
            return self
        }
        return navVC
    }
    
    @IBAction func sendBtnAction(_ sender: Any) {
        storeAndShare(withURL: savePath!)
    }
}


extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
    var localizedName: String? {
        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
    }
}
