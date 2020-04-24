//
//  editingPageViewController.swift
//  creatorProject
//
//  Created by GuantingLiu on 2019/11/5.
//  Copyright © 2019 GuantingLiu. All rights reserved.
//

import UIKit

class editingPageViewController:UIViewController, UIDocumentInteractionControllerDelegate {

    @IBAction func pinchGestureRec(_ sender: UIPinchGestureRecognizer) {

        if(croppedimg.frame.width > editView.frame.width ) {
            print("HI")
            return
        }
        timer.invalidate()
        pinchTipView.isHidden = true
        croppedimg.transform = CGAffineTransform(scaleX: sender.scale, y: sender.scale)
        
        
    }
    @IBOutlet weak var croppedimg: UIImageView!
    @IBOutlet weak var OKimgView: UIImageView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var preView: UIImageView!
    @IBOutlet weak var editView: UIImageView!
    @IBOutlet weak var paperSizeSeg: UISegmentedControl!
    @IBOutlet weak var foldNumSeg: UISegmentedControl!
    @IBOutlet weak var foldTypeSeg: UISegmentedControl!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var editBGView: UIImageView!
    @IBOutlet weak var pinchTipView: UIImageView!
    var img:UIImage?
    var OKimg:UIImage?
    var shouldPrcoess:Bool?
    let startRange:CGFloat = 0.0, endRange:CGFloat = 0.0
    
    var savePath:URL?
    let dICon = UIDocumentInteractionController()
    
    var inactivequeue:DispatchQueue?
    var counter_inactQ:Int = 0
    
    var alertCtr:UIAlertController?
    let progressView:UIProgressView = UIProgressView(frame: CGRect())
    let progressStatusString:[String]=["\n\n\n\n\n\n\nAppyling ChromaKey effect\n","\n\n\n\n\n\n\nFinding edge point\n","\n\n\n\n\n\n\nFinding edge point\n","\n\n\n\n\n\n\nFinding edge point\n","\n\n\n\n\n\n\nFinding edge point\n","\n\n\n\n\n\n\nCropping image\n"]
    var progressImageView:UIImageView = UIImageView()
    var timer = Timer()
    override func viewDidLoad() {
        super.viewDidLoad()
        //imgView.image = img
        view.backgroundColor = UIColor(red: 160/255.0, green: 188/255.0, blue: 193/255.0, alpha: 1)
        navigationController?.navigationBar.barTintColor = UIColor(red: 194/255.0, green: 222/255.0, blue: 226/255.0, alpha: 0.8)
        //navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor(red: 19/255.0, green: 54/255.0, blue: 118/255.0, alpha: 0.8)]

        //view.backgroundColor = UIColor(patternImage: UIImage(named: "editBG.png")!)
        
        shouldPrcoess = true
        imgView.image = img
        // Do any additional setup after loading the view.
        navigationController?.setNavigationBarHidden(false, animated:true)
        //print(img!.ciImage)
              
        dICon.delegate = self

        self.showProgress()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if shouldPrcoess!{
            OKimg = UIImage.init(ciImage:filterPixels(foregroundCIImage:CIImage(cgImage:img!.cgImage!)))
            OKimgView.image = OKimg
            
            progressImageView.image = resizeImageA(image: OKimgView.image!, newHeight: 81)
            //progressImageView.image = OKimgView.image!.scaleImage(scaleSize: 0.0815)
            //progressImageView.layer.minificationFilter = CALayerContentsFilter.trilinear
            //progressImageView.layer.minificationFilterBias = 2
            //progressImageView.layer.shouldRasterize = true;
            //progressImageView.layer.rasterizationScale = 4;
            

            
            let OKdata:Data? = OKimg?.pngData()

            self.findEdgePoint(image: UIImage.init(data: OKdata!)!)
  
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
        progressView.progress += 0.125
        
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
    
    
    
    func findEdgePoint(image:UIImage) -> Void{
        
        var ans = [Int](), ans_new = [Int]()             //var breaker:Bool = false
        for _ in 0...7{ ans.append(0) }                  //intialize array with capacity 8
        
        
        let whiteThreshold = 240                         //determine transparent domain be 0 to 5
        let bytesPerPixel:Int = 4
       // print(pixels)
        
        
        
        DispatchQueue.main.async {
            self.alertCtr?.title = "Prcessing...(2/3)"
            self.alertCtr?.message = self.progressStatusString[self.counter_inactQ+1]
        }
        
        
        //merge found edge, dispatch ui update event to mainQueue
        let returnQueue = DispatchQueue(label: "com.guanting.creatorproject.returnqueue", qos: .userInteractive, attributes: .initiallyInactive)
        returnQueue.async {
            print("return cropeed")
            
            DispatchQueue.main.async {
                self.alertCtr?.title = "Prcessing...(3/3)"
                self.alertCtr?.message = self.progressStatusString[5]
                self.progressView.progress+=0.125
                
                self.croppedimg.image = self.cropImage(image: self.OKimg!, toRect: CGRect(x: CGFloat(ans_new[0])/2, y: CGFloat(ans_new[1])/2     //divided by 2 to trans. into point-level
                , width:CGFloat(ans_new[2]-ans_new[0])/2, height: CGFloat(ans_new[3]-ans_new[1])/2))
                
                self.croppedimg.frame = CGRect(x: self.croppedimg.frame.origin.x, y: self.croppedimg.frame.origin.y
                    , width: 130*(self.croppedimg.image?.size.width)!/(self.croppedimg.image?.size.height)!, height: 130)
                self.editView.addSubview(self.croppedimg)
                self.croppedimg.frame.origin.x = (self.croppedimg.superview?.frame.width)!/2 - self.croppedimg.frame.width/2                    //move it to parent view 's center
                self.croppedimg.frame.origin.y = (self.croppedimg.superview?.frame.height)!/2 - self.croppedimg.frame.height/2
                
                self.progressImageView.image = self.resizeImageA(image: self.croppedimg.image!, newHeight: 81)


                
                self.alertCtr?.dismiss(animated: true, completion: nil)
                self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {(timer) in
                    self.performAni()
                })
                
            }
            
            self.shouldPrcoess = false
        }
        
        
        let concurrentQueue = DispatchQueue(label: "com.guanting.creatorproject.findedge", qos: .default, attributes: .concurrent)
        
        concurrentQueue.async {
            let imageData = CGDataProvider(data: (image.cgImage?.dataProvider?.data)!)
            let pixels = CFDataGetBytePtr(imageData?.data)
                                  
            var breaker = false
            for x in 0...Int(image.size.width){                                                                   //find left edge
                if breaker == true { break }
                for y in 0...Int(image.size.height){
                    let pixelPivot = (x+y*Int(image.size.width))*bytesPerPixel
                    let rValue:UInt8 = pixels![pixelPivot], gValue:UInt8 = pixels![pixelPivot + 1]
                    let bValue:UInt8 = pixels![pixelPivot + 2], aValue:UInt8 = pixels![pixelPivot + 3]
                    //print(x," ",y," ",aValue," ",rValue," ",gValue," ",bValue)
                    if !((rValue > whiteThreshold && gValue > whiteThreshold && bValue > whiteThreshold)
                    || (rValue < 255-whiteThreshold && gValue < 255-whiteThreshold && bValue < 255-whiteThreshold)){ //check if being in trans. domain
                        ans[0] = x
                        ans[1] = y
                        self.counter_inactQ+=1
                        DispatchQueue.main.async {
                            //self.alertCtr?.title = "Prcessing...(2/3)"
                            self.alertCtr?.message = self.progressStatusString[self.counter_inactQ+1]
                            self.progressView.progress+=0.1875
                        }
                        breaker = true                                                                              //break to outer for statment
                        print(x," ",y," ",aValue," ",rValue," ",gValue," ",bValue)
                        break
                        
                    }
                    
                }
            }
            if self.counter_inactQ==4 {             //ans_new ADT:[L-TopX, L-TopY ,R-BtmX, R-BtmY]
                ans_new.append(ans[0])              //left-top point    x
                ans_new.append(ans[3])              //                  y
                ans_new.append(ans[4])              //right-btm point   x
                ans_new.append(ans[7])              //                  y
                returnQueue.activate()
                self.inactivequeue?.activate()
            }
                
        }
        
        concurrentQueue.async {
            let imageData = CGDataProvider(data: (image.cgImage?.dataProvider?.data)!)
            let pixels = CFDataGetBytePtr(imageData?.data)
            
            var breaker = false                                                                                        //reset breaker, find top egde
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
                            ans[2] = x
                            ans[3] = y
                            self.counter_inactQ+=1
                            DispatchQueue.main.async {
                                //self.alertCtr?.title = "Prcessing...(2/3)"
                                self.alertCtr?.message = self.progressStatusString[self.counter_inactQ+1]
                                self.progressView.progress+=0.1875
                            }
                            breaker = true                                                                          //break to outer for statment
                            print(x," ",y," ",aValue," ",rValue," ",gValue," ",bValue)
                            break
                        }
                    }
                }
            }
            if self.counter_inactQ==4 {
                ans_new.append(ans[0])              //left-top point    x
                ans_new.append(ans[3])              //                  y
                ans_new.append(ans[4])              //right-btm point   x
                ans_new.append(ans[7])              //                  y
                returnQueue.activate()
                self.inactivequeue?.activate()
            }
        }
        
        concurrentQueue.async {
            let imageData = CGDataProvider(data: (image.cgImage?.dataProvider?.data)!)
            let pixels = CFDataGetBytePtr(imageData?.data)
            
            var breaker = false                                                                                        //reset breaker, find top egde
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
                            ans[4] = x
                            ans[5] = y
                            self.counter_inactQ+=1
                            DispatchQueue.main.async {
                                //self.alertCtr?.title = "Prcessing...(2/3)"
                                self.alertCtr?.message = self.progressStatusString[self.counter_inactQ+1]
                                self.progressView.progress+=0.1875
                            }
                            breaker = true                                                                        //break to outer for statment
                            print(x," ",y," ",aValue," ",rValue," ",gValue," ",bValue)
                            break
                        }
                    }
                }
            }
            if self.counter_inactQ==4 {
                ans_new.append(ans[0])              //left-top point    x
                ans_new.append(ans[3])              //                  y
                ans_new.append(ans[4])              //right-btm point   x
                ans_new.append(ans[7])              //                  y
                returnQueue.activate()
                self.inactivequeue?.activate()
            }
        }
        
        concurrentQueue.async {
            let imageData = CGDataProvider(data: (image.cgImage?.dataProvider?.data)!)
            let pixels = CFDataGetBytePtr(imageData?.data)
            
            var breaker = false                                                                                        //reset breaker, find btm egde
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
                            ans[6] = x
                            ans[7] = y
                            self.counter_inactQ+=1
                            DispatchQueue.main.async {
                                //self.alertCtr?.title = "Prcessing...(2/3)"
                                self.alertCtr?.message = self.progressStatusString[self.counter_inactQ+1]
                                self.progressView.progress+=0.1875
                            }
                            breaker = true                                                                          //break to outer for statment
                            print(x," ",y," ",aValue," ",rValue," ",gValue," ",bValue)
                            break
                        }
                    }
                }
            }
            if self.counter_inactQ==4 {
                ans_new.append(ans[0])              //left-top point    x
                ans_new.append(ans[3])              //                  y
                ans_new.append(ans[4])              //right-btm point   x
                ans_new.append(ans[7])              //                  y
                returnQueue.activate()
                self.inactivequeue?.activate()
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
        

        
        //return ans_new
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
    func resizeImageA(image: UIImage, newHeight: CGFloat) -> UIImage {
        let scale = newHeight / image.size.height
        let newWidth = image.size.width * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    
    func showProgress() -> Void{
        alertCtr = UIAlertController(title: "Processing...(1/3)", message: self.progressStatusString[0], preferredStyle: UIAlertController.Style.alert)
        alertCtr?.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (alertAction) in
            self.navigationController?.popViewController(animated: true)
            print("cancel processing image")
            
        }))
        progressView.progress = 0.0
        progressView.translatesAutoresizingMaskIntoConstraints = false;
        alertCtr?.view.addSubview(progressView)
        
        let btmConstraint = progressView.bottomAnchor.constraint(equalTo: alertCtr!.view!.bottomAnchor)
        btmConstraint.isActive = true
        btmConstraint.constant = -43
        
        progressView.leftAnchor.constraint(equalTo: alertCtr!.view!.leftAnchor).isActive = true
        progressView.rightAnchor.constraint(equalTo: alertCtr!.view!.rightAnchor).isActive = true
        
        
        progressImageView.image = imgView.image?.scaleImage(scaleSize: 0.12)
        //progressImageView.frame.size = CGSize(width: 114, height: 114*1.0/1.207)

        progressImageView.translatesAutoresizingMaskIntoConstraints = false
        progressImageView.contentMode = .scaleAspectFit
        progressImageView.clipsToBounds = true

        alertCtr?.view.addSubview(progressImageView)

//        let topC = progressImageView.topAnchor.constraint(equalTo: alertCtr!.view.topAnchor)
//        topC.isActive = true
//        topC.constant = 53
                
        let btmC = progressImageView.bottomAnchor.constraint(equalTo: progressView.bottomAnchor)
        btmC.isActive = true
        btmC.constant = -53
                
        let lftC = progressImageView.leftAnchor.constraint(equalTo: alertCtr!.view.leftAnchor)
        lftC.isActive = true
        lftC.constant = 60
        let rgtC = progressImageView.rightAnchor.constraint(equalTo: alertCtr!.view.rightAnchor)
        rgtC.isActive = true
        rgtC.constant = -60
        
//        let widC = progressView.widthAnchor.constraint(equalTo: alertCtr!.view.widthAnchor)
//        widC.isActive = true
//        widC.constant = 20
//        let hgtC = progressView.heightAnchor.constraint(equalTo: alertCtr!.view.heightAnchor)
//        hgtC.isActive = true
//        hgtC.constant = 20

        
        self.present(alertCtr!, animated: true, completion: nil)
    }

    @IBAction func rightNavBtn(_ sender: Any) {
        print("helllo")
        
        print(self.saveImage(image: preView.image!))
        storeAndShare(withURL: savePath!)
        
    }
    @IBAction func testBtn(_ sender: Any) {
        editBGView.image = UIImage(named: "editBG.png")
        
        let canvas = UIImage(named: "blank1.png")
        
        
        let lineColor = UIColor(red: 95.0/255, green: 200.0/255, blue: 170.0/255, alpha: 1)
        UIGraphicsBeginImageContext(canvas!.size)
        canvas?.draw(at: CGPoint(x: 0, y: 0))
        
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(8.0)
        context?.setLineCap(CGLineCap.round)
        context?.setLineDash(phase: 0.0, lengths: [CGFloat(16.0),CGFloat(32.0)])
        
                
        print(foldNumSeg.selectedSegmentIndex)
        switch foldTypeSeg.selectedSegmentIndex {
        case 0:
            let Px = Int((preView.image?.size.height)!/2)
            context?.move(to: CGPoint(x: Px, y:0))
            context?.addLine(to: CGPoint(x: Px, y: Px*2))
            context?.move(to: CGPoint(x: 0, y:Px))
            context?.addLine(to: CGPoint(x: Px*2, y:Px))
            context?.setStrokeColor(lineColor.cgColor)
            context?.strokePath()
            
            let canvasFinish = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            preView.image = canvasFinish
            
            
            for x in 1...3{
                if (x==2) {continue}
                preView.image = UIImage.imageByMergingImages(topImage: croppedimg.image!, bottomImage: preView.image!,Point: CGPoint(x: Px*x, y: Px),scaleForMe: croppedimg.frame.size.height/130)
                preView.image = UIImage.imageByMergingImages(topImage: croppedimg.image!, bottomImage: preView.image!,Point: CGPoint(x: Px*x, y: Px*3),scaleForMe: croppedimg.frame.size.height/130)
                
            }
            break
        case 1:
            let maxN = (croppedimg.image!.size.height * 130 / croppedimg.image!.size.height * 1.137896 * croppedimg.frame.size.height/130)
            var N = Int(1240/maxN)
            print(N)
            let M = slider.value/slider.maximumValue
            N = Int(Float(N)*M)
            for x in 0...foldNumSeg.selectedSegmentIndex+1 {
                let Px = Int((preView.image?.size.width)!)
                context?.move(to: CGPoint(x: Px*(x+1)/(foldNumSeg.selectedSegmentIndex+3), y: 0))
                context?.addLine(to: CGPoint(x: CGFloat(Px*(x+1)/(foldNumSeg.selectedSegmentIndex+3)), y: (preView.image?.size.height)!))
            }
            context?.setStrokeColor(lineColor.cgColor)
            context?.strokePath()
            
            let canvasFinish = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            preView.image = canvasFinish
            
            for x in 0...foldNumSeg.selectedSegmentIndex+2 {
                let p = Int((preView.image?.size.width)!)/(foldNumSeg.selectedSegmentIndex+3)
                let px = (x+1)*p - p/2
                
                for y in 0...N{
                    if(N==0) {N+=1}
                    let q = Int((preView.image?.size.height)!)/N
                    let qy = (y+1)*q - q/2
                    if(x%2==0){preView.image = UIImage.imageByMergingImagesRect(topImage: croppedimg.image!, bottomImage: preView.image!,Point: CGPoint(x: px, y: qy),scaleForMe: croppedimg.frame.size.height/130)}
                    else{preView.image = UIImage.imageByMergingImagesRect(topImage: croppedimg.image!.imageRotated(by: 90), bottomImage: preView.image!,Point: CGPoint(x: px, y: qy),scaleForMe: croppedimg.frame.size.height/130)}
                    
                    
                }
            }
            
            
            break
        case 2:
            
            let canvasFinish = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            preView.image = canvasFinish
            
            preView.image = UIImage.imageByMergingImagesRect(topImage: croppedimg.image!, bottomImage: preView.image!,Point: CGPoint(x: (preView.image?.size.width)!/2.0, y: (preView.image?.size.height)!/2.0),scaleForMe: croppedimg.frame.size.height/130)
            break
        default:
            print("No definition found.")
            break
        }
        
        
        
        
        //preView.addSubview(croppedimg)
        
        
        
    }
    @IBAction func testBtnDown(_ sender: Any) {
        editBGView.image = UIImage(named: "editBG_clicked.png")
    }
    @IBAction func foldTypeChanged(_ sender: Any) {
        if(foldTypeSeg.selectedSegmentIndex == 0||foldTypeSeg.selectedSegmentIndex == 2) {foldNumSeg.isEnabled = false ;slider.isEnabled = false}
        else {foldNumSeg.isEnabled = true; slider.isEnabled = true;}
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
    func  performAni() -> Void {
        let ani = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1, delay: 0, options: [.repeat, .autoreverse], animations: {
            if(self.pinchTipView.alpha == 1.0) {self.pinchTipView.alpha = 0.0}
            else{self.pinchTipView.alpha = 1.0}
        }, completion:nil)
        ani.startAnimation()
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
    
      func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
      }
    func scaleImage(scaleSize:CGFloat)->UIImage {
        let reSize = CGSize(width: self.size.width * scaleSize, height: self.size.height * scaleSize)
        return resizeImage(targetSize: reSize)
    }
    static func imageByMergingImages(topImage: UIImage, bottomImage: UIImage, Point: CGPoint, scaleForMe: CGFloat = 1.0) -> UIImage {
        let size = bottomImage.size
        let container = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
        UIGraphicsGetCurrentContext()!.interpolationQuality = .high
        bottomImage.draw(in: container)

        let topWidth = topImage.size.width * 130 / topImage.size.height * 1.137896 * scaleForMe
        let topHeight = topImage.size.height * 130 / topImage.size.height * 1.137896 * scaleForMe
        let topX = (Point.x / 2.0) - (topWidth / 2.0)
        let topY = (Point.y / 2.0) - (topHeight / 2.0)

        topImage.draw(in: CGRect(x: topX, y: topY, width: topWidth, height: topHeight), blendMode: .normal, alpha: 1.0)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    static func imageByMergingImagesRect(topImage: UIImage, bottomImage: UIImage, Point: CGPoint, scaleForMe: CGFloat = 1.0) -> UIImage {
        let size = bottomImage.size
        let container = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
        UIGraphicsGetCurrentContext()!.interpolationQuality = .high
        bottomImage.draw(in: container)

        let topWidth = topImage.size.width * 130 / topImage.size.height * 1.137896 * scaleForMe
        let topHeight = topImage.size.height * 130 / topImage.size.height * 1.137896 * scaleForMe
        let topX = Point.x  - (topWidth / 2.0)
        let topY = Point.y  - (topHeight / 2.0)

        topImage.draw(in: CGRect(x: topX, y: topY, width: topWidth, height: topHeight), blendMode: .normal, alpha: 1.0)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    func imageRotated(by degrees: CGFloat) -> UIImage {

        let orientation = CGImagePropertyOrientation(rawValue: UInt32(imageOrientation.rawValue))
        // Create CIImage respecting image's orientation
        guard let inputImage = CIImage(image: self)?.oriented(orientation!)
            else { return self }

        // Flip the image itself
        let flip = CGAffineTransform(scaleX: -1, y: 1)
        let outputImage = inputImage.transformed(by: flip)

        // Create CGImage first
        guard let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent)
            else { return self }

        // Create output UIImage from CGImage
        return UIImage(cgImage: cgImage)
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
        //self.layer.borderColor = UIColor.red.cgColor
        self.isUserInteractionEnabled = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        self.localTouchPosition = touch?.preciseLocation(in: self)
        
       
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //print(superview?.frame.origin.x)
        super.touchesMoved(touches, with: event)
        let touch = touches.first
        guard let location = touch?.location(in: self.superview), let localTouchPosition = self.localTouchPosition else{
            return
        }
        if(self.frame.origin.x <= 0) {
            self.frame.origin.x = 0.5
        }
        else if(self.frame.origin.y <= 0){
            self.frame.origin.y = 0.5
        }
        else if ((self.frame.origin.x + self.frame.width) > (superview?.frame.width)!){
            self.frame.origin.x = (superview?.frame.width)! - self.frame.width
        }
        else if ((self.frame.origin.y + self.frame.height) > (superview?.frame.height)!){
            self.frame.origin.y = (superview?.frame.height)! - self.frame.height
        }
        else{
            self.frame.origin = CGPoint(x: location.x - localTouchPosition.x, y: location.y - localTouchPosition.y)
        }
        
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.localTouchPosition = nil
        if(self.frame.origin.x <= 0) {
            self.frame.origin.x = 0.5
            
            return
        }
        else if(self.frame.origin.y <= 0){
            self.frame.origin.y = 0.5
            return
        }
        else if ((self.frame.origin.x + self.frame.width) > (superview?.frame.width)!){
            self.frame.origin.x = (superview?.frame.width)! - self.frame.width
            return
        }
        else if ((self.frame.origin.y + self.frame.height) > (superview?.frame.height)!){
            self.frame.origin.y = (superview?.frame.height)! - self.frame.height
            return
        }
        
    }
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */

}
