//
//  ViewController.swift
//  mycam
//
//  Created by Tim Sutcliffe on 7/11/16.
//  Copyright © 2016 Tim Sutcliffe. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary



class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var recordButton: UIButton!

    var movieFileOutput: AVCaptureMovieFileOutput?
    var sessionQueue: dispatch_queue_t!
    var backgroundRecordId: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid


    @IBAction func recordButtionAction(sender: AnyObject) {

        dispatch_async(self.sessionQueue, {
            if !self.movieFileOutput!.recording{
                print("start recording")
//                //self.lockInterfaceRotation = true
//
////                if UIDevice.currentDevice().multitaskingSupported {
////                    self.backgroundRecordId = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({})
////
////                }
//
//                self.movieFileOutput!.connectionWithMediaType(AVMediaTypeVideo).videoOrientation =
//                    AVCaptureVideoOrientation(rawValue: (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation.rawValue )!
//


//                // Turning OFF flash for video recording
//                //ViewController.setFlashMode(AVCaptureFlashMode.Off, device: self.videoDeviceInput!.device)
//
               let outputFilePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("movie.mov")
//
//                //NSTemporaryDirectory().stringByAppendingPathComponent( "movie".stringByAppendingPathExtension("mov")!)
//
                self.movieFileOutput!.startRecordingToOutputFileURL( outputFilePath, recordingDelegate: self)
//
//
            }else{
                print("stop recording")
                self.movieFileOutput!.stopRecording()
            }
        })



    }

    var session: AVCaptureSession?

    var previewLayer: AVCaptureVideoPreviewLayer?


    override func viewDidLoad() {
        super.viewDidLoad()

        let sessionQueue: dispatch_queue_t = dispatch_queue_create("session queue",DISPATCH_QUEUE_SERIAL)
        self.sessionQueue = sessionQueue

        

        // Create our recording session
        let session: AVCaptureSession = AVCaptureSession()
        self.session = session


        // Configure our session
        session.sessionPreset = AVCaptureSessionPresetMedium

        // Start the session
        session.startRunning()

        // Set the input
        var device: AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)


        var error: NSError? = nil

        var videoDeviceInput: AVCaptureDeviceInput?
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: device)
        } catch let error1 as NSError {
            error = error1
            videoDeviceInput = nil
        } catch {
            fatalError()
        }


        if session.canAddInput(videoDeviceInput){
            session.addInput(videoDeviceInput)


            dispatch_async(dispatch_get_main_queue(), {
                // Why are we dispatching this to the main queue?
                // Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView can only be manipulated on main thread.
                // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.

                // Set up a preview layer
                self.previewLayer = AVCaptureVideoPreviewLayer(session: session)

                if let previewLayer = self.previewLayer{
                    previewLayer.frame = CGRectMake(0, 0, 200, 200)
                    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;


                    self.previewView.layer.addSublayer(previewLayer)
                } else {
                    print("no preview layer")
                }

            })

        }

        // Add output to session
        let movieFileOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()

        if session.canAddOutput(movieFileOutput){
            session.addOutput(movieFileOutput)
            self.movieFileOutput = movieFileOutput
        } else {
            print("didn't add output")
        }


    }

    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        var filename = "CroppedVideo23"
        //let croppedVideoPath =  "crop3.mp4"


        let croppedVideoPath : String = String(format: "%@%@", NSTemporaryDirectory(), "output3.mov")


        //var asset : AVAsset = AVAsset.assetWithURL(outputFileURL) as AVAsset
        let asset : AVURLAsset = AVURLAsset(URL: outputFileURL, options: nil)

        var composition : AVMutableComposition = AVMutableComposition()
        composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))

        var clipVideoTrack : AVAssetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack

        var videoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTimeMake(1, 60)
        videoComposition.renderSize = CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.height)

        var instruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30))


        var transformer: AVMutableVideoCompositionLayerInstruction =
            AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)


        var t1: CGAffineTransform = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, -(clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height)/2 )
        var t2: CGAffineTransform = CGAffineTransformRotate(t1, CGFloat(M_PI_2))

        var finalTransform: CGAffineTransform = t2

        transformer.setTransform(finalTransform, atTime: kCMTimeZero)

        instruction.layerInstructions = NSArray(object: transformer) as! [AVVideoCompositionLayerInstruction]
        videoComposition.instructions = NSArray(object: instruction) as! [AVVideoCompositionInstructionProtocol]


        var exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        exporter!.videoComposition = videoComposition
        exporter!.outputFileType = AVFileTypeQuickTimeMovie
        exporter!.outputURL = NSURL(fileURLWithPath: croppedVideoPath)

        exporter!.exportAsynchronouslyWithCompletionHandler({ () -> Void in

            dispatch_async(dispatch_get_main_queue()) {
                () -> Void in
                let outputURL:NSURL = exporter!.outputURL!;
                //self.videoURL = outputURL
                let asset:AVURLAsset = AVURLAsset(URL: outputURL, options: nil)
                print(outputURL)

                let backgroundRecordId: UIBackgroundTaskIdentifier = self.backgroundRecordId
                self.backgroundRecordId = UIBackgroundTaskInvalid
        
                ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(outputURL, completionBlock: {
                    (assetURL:NSURL!, error:NSError!) in
                    if error != nil{
                        print(error)
        
                    }
        
                    do {
                        try NSFileManager.defaultManager().removeItemAtURL(outputFileURL)
                    } catch _ {
                    }
        
                    if backgroundRecordId != UIBackgroundTaskInvalid {
                        UIApplication.sharedApplication().endBackgroundTask(backgroundRecordId)
                    }
        
                })


            }

        })


        //        exporter!.exportAsynchronouslyWithCompletionHandler({
        //
        //            //display video after export is complete, for example...
        //            let outputURL:NSURL = exporter!.outputURL!;
        //            print("Cropped video saved at \(outputURL)")
        //            //self.saveVideoEvent()
        //
        //        })
    }




//    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
//
//        if(error != nil){
//            print(error)
//        }
//
//        print("hello from delegate")
//
//        //self.lockInterfaceRotation = false
//
//        // Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
//
//        let backgroundRecordId: UIBackgroundTaskIdentifier = self.backgroundRecordId
//        self.backgroundRecordId = UIBackgroundTaskInvalid
//
//        ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(outputFileURL, completionBlock: {
//            (assetURL:NSURL!, error:NSError!) in
//            if error != nil{
//                print(error)
//
//            }
//
//            do {
//                try NSFileManager.defaultManager().removeItemAtURL(outputFileURL)
//            } catch _ {
//            }
//
//            if backgroundRecordId != UIBackgroundTaskInvalid {
//                UIApplication.sharedApplication().endBackgroundTask(backgroundRecordId)
//            }
//
//        })
//
//
//    }


}

