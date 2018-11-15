//
//  QRScannerController.swift
//  QRScanner
//
//  Created by Dinesh Garg on 11/13/18.
//  Copyright © 2018 Dinesh Garg. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

// Play sound, vibrate, etc.
// If need to control the sound, AVFoundation should be used.

class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate{
    
    // input source audio (mic) or video (camera) from which it will be grabbing the data.
    var captureSession:AVCaptureSession?
    var captureDevice:AVCaptureDevice?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    
    let codeFrame:UIView = {
        let codeFrame = UIView()
        codeFrame.layer.borderColor = UIColor.green.cgColor
        codeFrame.layer.borderWidth = 2
        codeFrame.frame = CGRect.zero
        codeFrame.translatesAutoresizingMaskIntoConstraints = false
        return codeFrame
    }()
    
    let codeLabel:UILabel = {
        let codeLabel = UILabel()
        codeLabel.font = UIFont(name: "Helvetica", size: 12)
        codeLabel.frame = CGRect.zero
        codeLabel.numberOfLines = 0
        codeLabel.minimumScaleFactor = 0.75
        codeLabel.backgroundColor = .white
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        return codeLabel
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if let captureDevice = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                
                let captureSession = AVCaptureSession()
                captureSession.addInput(input)
                
                let captureMetadataOutput = AVCaptureMetadataOutput()
                captureSession.addOutput(captureMetadataOutput)
                
                captureMetadataOutput.setMetadataObjectsDelegate(self, queue: .main)
                captureMetadataOutput.metadataObjectTypes = [.code128, .qr, .ean13,  .ean8, .code39] //AVMetadataObject.ObjectType
                
                captureSession.startRunning()
                
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                videoPreviewLayer?.videoGravity = .resizeAspectFill
                videoPreviewLayer?.frame = view.layer.bounds
                view.layer.addSublayer(videoPreviewLayer!)
                
            } catch {
                print("Error device input");
            }
        }
        
        view.addSubview(codeLabel)
        codeLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        codeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        codeLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        codeLabel.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count == 0 {
            //print("No Input Detected")
            codeFrame.frame = CGRect.zero
            codeLabel.text = "No Data"
            return
        }
        
        let metadataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        guard let stringCodeValue = metadataObject.stringValue else { return }
        
        view.addSubview(codeFrame)
        
        guard let barcodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObject) else { return }
        codeFrame.frame = barcodeObject.bounds
        codeLabel.text = stringCodeValue
        
        // Play system sound with custom mp3 file
        if let customSoundUrl = Bundle.main.url(forResource: "beep-07", withExtension: "mp3") {
            var customSoundId: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(customSoundUrl as CFURL, &customSoundId)
            //let systemSoundId: SystemSoundID = 1016  // to play apple's built in sound, no need for upper 3 lines
            
            AudioServicesAddSystemSoundCompletion(customSoundId, nil, nil, { (customSoundId, _) -> Void in
                AudioServicesDisposeSystemSoundID(customSoundId)
            }, nil)
            
            AudioServicesPlaySystemSound(customSoundId)
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Present a controller.
    let codeStringLabel:UILabel = {
        let codeLabel = UILabel()
        codeLabel.font = UIFont(name: "Helvetica", size: 12)
        codeLabel.frame = CGRect.zero
        codeLabel.numberOfLines = 0
        codeLabel.minimumScaleFactor = 0.75
        codeLabel.backgroundColor = .white
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        return codeLabel
    }()
    
    func displayDetailsViewController(scannedCode: String) {
        let detailsViewController = UIViewController()
        detailsViewController.view.frame = self.view.frame
        codeStringLabel.text = scannedCode
        detailsViewController.view.addSubview(codeStringLabel)
        
        //navigationController?.pushViewController(detailsViewController, animated: true)
        present(detailsViewController, animated: true, completion: nil)
    }

}

