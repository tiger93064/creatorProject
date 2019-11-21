//
//  editingPageViewController.swift
//  creatorProject
//
//  Created by GuantingLiu on 2019/11/5.
//  Copyright © 2019 GuantingLiu. All rights reserved.
//

import UIKit

class editingPageViewController:UIViewController, UIDocumentInteractionControllerDelegate {

    @IBOutlet weak var croppedimg: UIImageView!
    @IBOutlet weak var OKimgView: UIImageView!
    @IBOutlet weak var imgView: DraggableImage!
    var img:UIImage?
    var OKimg:UIImage?
    var shouldPrcoess:Bool?
    let startRange:CGFloat = 0.0, endRange:CGFloat = 0.0
    
    var savePath:URL?
    let dICon = UIDocumentInteractionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //imgView.image = img
        view.backgroundColor = UIColor.lightGray
        shouldPrcoess = true
        imgView.image = img
        // Do any additional setup after loading the view.
        navigationController?.setNavigationBarHidden(false, animated:true)
        //print(img!.ciImage)
              
        dICon.delegate = self

    }
    
    override func viewDidAppear(_ animated: Bool) {
        if shouldPrcoess!{
            OKimg = UIImage.init(ciImage: filterPixels(foregroundCIImage:CIImage(cgImage: img!.cgImage!)))
                    
            let OKdata:Data? = OKimg?.pngData()
            
            //print(self.findEdgePoint(image: UIImage.init(contentsOfFile: filename!.path)!))
            let cropinfo = self.findEdgePoint(image: UIImage.init(data: OKdata!)!)                                              //ADT:[L-TopX, L-TopY ,R-BtmX, R-BtmY]
            print(cropinfo)
            //print(self.findEdgePoint(image: UIImage.init(named: "image.png")!))   tested OK
            OKimgView.image = OKimg
            
            croppedimg.image = cropImage(image: OKimg!, toRect: CGRect(x: CGFloat(cropinfo[0])/2, y: CGFloat(cropinfo[1])/2     //divided by 2 to trans. into point-level
                , width:CGFloat(cropinfo[2]-cropinfo[0])/2, height: CGFloat(cropinfo[3]-cropinfo[1])/2))
            
            shouldPrcoess = false
            
            
        }
    }
    
    @objc func someAction(_ sender:UITapGestureRecognizer){
        let point = sender.location(in: self.view)
       print(point)
        
    }
    
    
    func getHue(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGFloat {
        let color = UIColor(red: red, green: green, blue: blue, alpha: 1)
        var hue: CGFloat = 0
        color.getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
        return hue
    }
    func chromaKeyFilter(fromHue: CGFloat, toHue: CGFloat) -> CIFilter? {
        // 1
        let size = 64
        var cubeRGB = [Float]()

        // 2
        for z in 0 ..< size {
            let blue = CGFloat(z) / CGFloat(size-1)
            for y in 0 ..< size {
                let green = CGFloat(y) / CGFloat(size-1)
                for x in 0 ..< size {
                    let red = CGFloat(x) / CGFloat(size-1)

                    // 3
                    let hue = getHue(red: red, green: green, blue: blue)
                    let alpha: CGFloat = (hue >= fromHue && hue <= toHue) ? 0: 1

                    // 4
                    cubeRGB.append(Float(red * alpha))
                    cubeRGB.append(Float(green * alpha))
                    cubeRGB.append(Float(blue * alpha))
                    cubeRGB.append(Float(alpha))
                }
            }
        }

        let data = Data(buffer: UnsafeBufferPointer(start: &cubeRGB, count: cubeRGB.count))

        // 5
        let colorCubeFilter = CIFilter(name: "CIColorCube", parameters: ["inputCubeDimension": size, "inputCubeData": data])
        return colorCubeFilter
    }
    
    
    func filterPixels(foregroundCIImage: CIImage) -> CIImage {
        // Remove Green from the Source Image
        let chromaCIFilter = self.chromaKeyFilter(fromHue: startRange, toHue: endRange)
        chromaCIFilter?.setValue(foregroundCIImage, forKey: kCIInputImageKey)
        let sourceCIImageWithoutBackground = chromaCIFilter?.outputImage
        var image = CIImage()
        if let filteredImage = sourceCIImageWithoutBackground {
            image = filteredImage
        }
        return image
    }
    
    
    
    func findEdgePoint(image:UIImage) -> [Int]{
        
        var ans = [Int](), ans_new = [Int]()
        var breaker:Bool = false
        
        let imageData = CGDataProvider(data: (image.cgImage?.dataProvider?.data)!)
        let pixels = CFDataGetBytePtr(imageData?.data)
        
        let whiteThreshold = 240                                                                              //determine transparent domain be 0 to 5
        let bytesPerPixel:Int = 4
       // print(pixels)
        for x in 0...Int(image.size.width){                                                                   //find left edge
            if breaker == true { break }
            for y in 0...Int(image.size.height){
                let pixelPivot = (x+y*Int(image.size.width))*bytesPerPixel
                let rValue:UInt8 = pixels![pixelPivot], gValue:UInt8 = pixels![pixelPivot + 1]
                let bValue:UInt8 = pixels![pixelPivot + 2], aValue:UInt8 = pixels![pixelPivot + 3]
                //print(x," ",y," ",aValue," ",rValue," ",gValue," ",bValue)
                if !((rValue > whiteThreshold && gValue > whiteThreshold && bValue > whiteThreshold)
                || (rValue < 255-whiteThreshold && gValue < 255-whiteThreshold && bValue < 255-whiteThreshold)){ //check if being in trans. domain
                    ans.append(x)
                    ans.append(y)
                    breaker = true                                                                              //break to outer for statment
                    print(x," ",y," ",aValue," ",rValue," ",gValue," ",bValue)
                    break
                    
                }
                
            }
        }
        
        breaker = false                                                                                        //reset breaker, find top egde
        for y in 0...Int(image.size.height){
            if breaker == true { break }
            for x in 0...Int(image.size.width){
                let pixelPivot = (x+y*Int(image.size.width))*bytesPerPixel
                let rValue:UInt8 = pixels![pixelPivot], gValue:UInt8 = pixels![pixelPivot + 1]
                let bValue:UInt8 = pixels![pixelPivot + 2], aValue:UInt8 = pixels![pixelPivot + 3]
                //print(x," ",y," ",aValue," ",rValue," ",gValue," ",bValue)
                if !((rValue > whiteThreshold && gValue > whiteThreshold && bValue > whiteThreshold)
                || (rValue < 255-whiteThreshold && gValue < 255-whiteThreshold && bValue < 255-whiteThreshold)){ //check if being in trans. domain
                    if rValue != 0 && gValue != 0 && bValue != 0{
                        ans.append(x)
                        ans.append(y)
                        breaker = true                                                                          //break to outer for statment
                        print(x," ",y," ",aValue," ",rValue," ",gValue," ",bValue)
                        break
                    }
                }
            }
        }
        
        breaker = false                                                                                        //reset breaker, find top egde
        for x in (0...Int(image.size.width)).reversed(){
            if breaker == true { break }
            for y in 0...Int(image.size.height){
                let pixelPivot = (x+y*Int(image.size.width))*bytesPerPixel
                let rValue:UInt8 = pixels![pixelPivot], gValue:UInt8 = pixels![pixelPivot + 1]
                let bValue:UInt8 = pixels![pixelPivot + 2], aValue:UInt8 = pixels![pixelPivot + 3]
                //print(x," ",y," ",aValue," ",rValue," ",gValue," ",bValue)
                if !((rValue > whiteThreshold && gValue > whiteThreshold && bValue > whiteThreshold)
                || (rValue < 255-whiteThreshold && gValue < 255-whiteThreshold && bValue < 255-whiteThreshold)){ //check if being in trans. domain
                    if rValue != 0 && gValue != 0 && bValue != 0{
                        ans.append(x)
                        ans.append(y)
                        breaker = true                                                                        //break to outer for statment
                        print(x," ",y," ",aValue," ",rValue," ",gValue," ",bValue)
                        break
                    }
                }
            }
        }
        
        breaker = false                                                                                        //reset breaker, find btm egde
        for y in (0...Int(image.size.height)).reversed(){
            if breaker == true { break }
            for x in 0...Int(image.size.width){
                let pixelPivot = (x+y*Int(image.size.width))*bytesPerPixel
                let rValue:UInt8 = pixels![pixelPivot], gValue:UInt8 = pixels![pixelPivot + 1]
                let bValue:UInt8 = pixels![pixelPivot + 2], aValue:UInt8 = pixels![pixelPivot + 3]
                //print(x," ",y," ",aValue," ",rValue," ",gValue," ",bValue)
                if !((rValue > whiteThreshold && gValue > whiteThreshold && bValue > whiteThreshold)
                || (rValue < 255-whiteThreshold && gValue < 255-whiteThreshold && bValue < 255-whiteThreshold)){ //check if being in trans. domain
                    if rValue != 0 && gValue != 0 && bValue != 0{
                        ans.append(x)
                        ans.append(y)
                        breaker = true                                                                          //break to outer for statment
                        print(x," ",y," ",aValue," ",rValue," ",gValue," ",bValue)
                        break
                    }
                }
            }
        }
        
        
       
        //CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(image2.CGImage));
                      
//        const UInt8 *pixels = CFDataGetBytePtr(imageData);
//        UInt8 blackThreshold = 10; // or some value close to 0
//        int bytesPerPixel = 4;
//        for(int x = 0; x < width1; x++) {
//          for(int y = 0; y < height1; y++) {
//            int pixelStartIndex = (x + (y * width1)) * bytesPerPixel;
//            UInt8 alphaVal = pixels[pixelStartIndex]; // can probably ignore this value
//            UInt8 redVal = pixels[pixelStartIndex + 1];
//            UInt8 greenVal = pixels[pixelStartIndex + 2];
//            UInt8 blueVal = pixels[pixelStartIndex + 3];
//            if(redVal < blackThreshold && blueVal < blackThreshold && greenVal < blackThreshold) {
//              //This pixel is close to black...do something with it
//            }
//          }
//        }
        ans_new.append(ans[0])              //left-top point    x
        ans_new.append(ans[3])              //                  y
        ans_new.append(ans[4])              //right-btm point   x
        ans_new.append(ans[7])              //                  y



        return ans_new
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func loadImageFromDocumentDirectory(nameOfImage : String) -> UIImage {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath = paths.first{
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent("Screenshots/\(nameOfImage)")
            guard let image = UIImage(contentsOfFile: imageURL.path) else { return  UIImage.init(named: "fulcrumPlaceholder")!}
            return image
        }
        return UIImage.init(named: "imageDefaultPlaceholder")!
    }
    
    func cropImage(image: UIImage, toRect: CGRect) -> UIImage? {
        
        let cgImage = convertCIImageToCGImage(ciImage: image.ciImage!)
        let croppedCGImage:CGImage = cgImage.cropping(to: toRect)!

        return UIImage.init(cgImage: croppedCGImage)
                       
    }
    
    func convertCIImageToCGImage(ciImage:CIImage) -> CGImage{

            let ciContext = CIContext.init()
            let cgImage:CGImage = ciContext.createCGImage(ciImage, from: ciImage.extent)!
        
            return cgImage
    }
    func convert(cmage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }

    @IBAction func rightNavBtn(_ sender: Any) {
        print("helllo")
        
        print(self.saveImage(image: OKimg!))
        storeAndShare(withURL: savePath!)
        
    }
}








extension editingPageViewController{                            //move from deleted previewPage
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
        
        
    
}

extension UIImage {
    func getPixelColor(pos: CGPoint) -> UIColor {

        let pixelData = self.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4

        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)

        return UIColor(red: r, green: g, blue: b, alpha: a)
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

class DraggableImage: UIImageView {

    var localTouchPosition : CGPoint?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.red.cgColor
        self.isUserInteractionEnabled = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        self.localTouchPosition = touch?.preciseLocation(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let touch = touches.first
        guard let location = touch?.location(in: self.superview), let localTouchPosition = self.localTouchPosition else{
            return
        }
        self.frame.origin = CGPoint(x: location.x - localTouchPosition.x, y: location.y - localTouchPosition.y)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.localTouchPosition = nil
    }
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */

}
