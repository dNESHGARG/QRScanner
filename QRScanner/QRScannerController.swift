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
    
    // MARK: QRScannerController -
    // Present a controller.
    // We should create a separate Controller class with its own view.
    // but, for the sake of example, we are using an instance of UIViewController.
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
        
        codeStringLabel.bottomAnchor.constraint(equalTo: detailsViewController.view.bottomAnchor).isActive = true
        codeStringLabel.centerXAnchor.constraint(equalTo: detailsViewController.view.centerXAnchor).isActive = true
        codeStringLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        codeStringLabel.widthAnchor.constraint(equalTo: detailsViewController.view.widthAnchor).isActive = true
        
        //navigationController?.pushViewController(detailsViewController, animated: true)
        present(detailsViewController, animated: true, completion: nil)
    }
    
    // MARK: QRScannerController - Setup
    func captureDataSetup() {
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
    }
    
    func setupView() {
        captureDataSetup()
        
        view.addSubview(codeLabel)
        
        codeLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        codeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        codeLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        codeLabel.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    }
    
    // MARK: - QRScannerController <AVCaptureMetadataOutputObjectsDelegate>
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
//        if let customSoundUrl = Bundle.main.url(forResource: "beep-07", withExtension: "mp3") {
//            var customSoundId: SystemSoundID = 0
//            AudioServicesCreateSystemSoundID(customSoundUrl as CFURL, &customSoundId)
//            //let systemSoundId: SystemSoundID = 1016  // to play apple's built in sound, no need for upper 3 lines
//
//            AudioServicesAddSystemSoundCompletion(customSoundId, nil, nil, { (customSoundId, _) -> Void in
//                AudioServicesDisposeSystemSoundID(customSoundId)
//            }, nil)
//
//            AudioServicesPlaySystemSound(customSoundId)
//        }
//
        
        let systemSoundId: SystemSoundID = 1016  // to play apple's built in sound, no need for upper 3 lines
        
        AudioServicesAddSystemSoundCompletion(systemSoundId, nil, nil, { (systemSoundId, _) -> Void in
            AudioServicesDisposeSystemSoundID(systemSoundId)
        }, nil)
        
        AudioServicesPlaySystemSound(systemSoundId)
        
        // Stop capturing and hence stop executing metadataOutput function over and over again
        captureSession?.stopRunning()
        
        // Call the function which performs navigation and pass the code string value we just detected
        //displayDetailsViewController(scannedCode: stringCodeValue)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setupView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}





