//
//  FaceDetectorVC.swift
//  Project_FaceDetector
//
//  Created by iOS Development on 6/28/18.
//  Copyright © 2018 Genisys. All rights reserved.
//



import UIKit
import AVFoundation
import CoreImage
import GPUImage
import Accelerate


class FaceDetectorVC: UIViewController,CameraDelegate {
   
    let cameraCanvasFrame = CGRect(x: 0, y: 0, width: 640, height: 480)
    let fbSize = Size(width: 640, height: 480)
    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyLow])
    let saturationFilter = SaturationAdjustment()
    let blendFilter = AlphaBlend()
    var camera : Camera!
    
    
    
    lazy var cameraView : RenderView = {
        let instance = RenderView()
        instance.backgroundRenderColor = .white
       // instance.fillMode = .preserveAspectRatioAndFill
        return instance
    }()
    
   
    lazy var lineGeneator : LineGenerator = {
        let instance = LineGenerator(size: self.fbSize)
        instance.lineWidth = 5
        return instance
    }()
   
    func setupCamera(){
        do {
            camera = try Camera(sessionPreset: AVCaptureSession.Preset.vga640x480.rawValue)
            camera.runBenchmark = true
            camera.delegate = self
            camera --> saturationFilter --> blendFilter --> cameraView
            lineGeneator --> blendFilter
            
            camera.startCapture()
        } catch  {
            fatalError("Camera could not initalised : \(error)")
        }
    }
    
    
    func didCaptureBuffer(_ sampleBuffer: CMSampleBuffer) {
        lineGeneator.renderLines([])
        
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer){
            let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))!
            
            let image = CIImage(cvPixelBuffer: pixelBuffer, options: attachments as? [String:AnyObject])
            
            var lines = [Line]()
            
            for feature in (faceDetector?.features(in: image, options: [CIDetectorImageOrientation:6]))!{
                if feature is CIFaceFeature {
                    lines = lines + faceLines(feature.bounds)
                }
            }
            lineGeneator.renderLines(lines)
        }
        
    }
    
    
    func faceLines(_ bounds:CGRect) -> [Line] {
        
        let flip = CGAffineTransform(scaleX: 1, y: -1)
        let rotate = flip.rotated(by: CGFloat(Double.pi / 2))
        let translate = rotate.translatedBy(x: -1, y: -1)
        let xform = translate.scaledBy(x: CGFloat(2/fbSize.width), y: CGFloat(2/fbSize.height))
        let glRect = bounds.applying(xform)
        
        let x = Float(glRect.origin.x)
        let y = Float(glRect.origin.y)
        let width = Float(glRect.size.width)
        let height = Float(glRect.size.height)
        
        let topLeft = Position(x, y)
        let topRight = Position(x + width, y)
        let bottomLeft = Position(x, y + height)
        let bottomRight = Position(x + width, y + height)
    
        let cordinates = [Line.segment(p1:topLeft, p2:topRight),
                          Line.segment(p1:topRight, p2:bottomRight),
                          Line.segment(p1:bottomRight, p2:bottomLeft),
                          Line.segment(p1:bottomLeft, p2:topLeft)]
                            
        
        
        return cordinates
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.view.addSubview(self.cameraView)
            self.cameraView.frame = self.view.frame
        }
        
        setupCamera()
        
    }
    
    
    
}






























