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


class Clip {

    static var clips = Array<Clip>()
    var previewPath:String!
//    //var tempImageUrl:String!
//    var imageData: uiImage!
//
    init (previewPath: String) {
        self.previewPath = previewPath
    }

}

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, UICollectionViewDelegate, UICollectionViewDataSource{

    @IBOutlet weak var collectionView: UICollectionView!

    let things = ["1", "2"]
    var movieFileOutput: AVCaptureMovieFileOutput?
    var sessionQueue: dispatch_queue_t!
    var backgroundRecordId: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! CollectionViewCell
        let previewPath = Clip.clips[indexPath.row].previewPath
        let preview = UIImage(contentsOfFile: previewPath)

            //.imageWithContentsOfFile(previewPath)!


        cell.cellImage.image = preview

        return cell
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Clip.clips.count
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let alertController = UIAlertController(title: "iOScreator", message:
            "Hello, world!", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))

        self.presentViewController(alertController, animated: true, completion: nil)
    }


    
    @IBAction func pressRecordButton(sender: AnyObject) {
        print("press")
        self.view.backgroundColor = UIColor.redColor()

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

                //if let timestamp = NSDate().timeIntervalSince1970 as? String {
                    let timestamp = String(NSDate().timeIntervalSince1970)
                    let outputFilePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("\(timestamp)movie153.mov")
                    print("outputFilePath is \(outputFilePath)")
                    self.movieFileOutput!.startRecordingToOutputFileURL( outputFilePath, recordingDelegate: self)
//                } else {
//                    print("nope")
//                }
                // let outputFilePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("movie153.mov")
                //
                //                //NSTemporaryDirectory().stringByAppendingPathComponent( "movie".stringByAppendingPathExtension("mov")!)
                //

                //
                //
            }else{
                //print("stop recording")
                //self.movieFileOutput!.stopRecording()
            }
        })

    }

    @IBAction func releaseRecordButton(sender: AnyObject) {
        print("release")
        self.view.backgroundColor = UIColor.whiteColor()

        if self.movieFileOutput!.recording{
            print("stop recording")
            self.movieFileOutput!.stopRecording()
        }
    }

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var recordButton: UIButton!




    @IBAction func recordButtionAction(sender: AnyObject) {

//        dispatch_async(self.sessionQueue, {
//            if !self.movieFileOutput!.recording{
//                print("start recording")
////                //self.lockInterfaceRotation = true
////
//////                if UIDevice.currentDevice().multitaskingSupported {
//////                    self.backgroundRecordId = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({})
//////
//////                }
////
////                self.movieFileOutput!.connectionWithMediaType(AVMediaTypeVideo).videoOrientation =
////                    AVCaptureVideoOrientation(rawValue: (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation.rawValue )!
////
//
//
////                // Turning OFF flash for video recording
////                //ViewController.setFlashMode(AVCaptureFlashMode.Off, device: self.videoDeviceInput!.device)
////
//               let outputFilePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("movie.mov")
////
////                //NSTemporaryDirectory().stringByAppendingPathComponent( "movie".stringByAppendingPathExtension("mov")!)
////
//                self.movieFileOutput!.startRecordingToOutputFileURL( outputFilePath, recordingDelegate: self)
////
////
//            }else{
//                print("stop recording")
//                self.movieFileOutput!.stopRecording()
//            }
//        })



    }

    var session: AVCaptureSession?

    var previewLayer: AVCaptureVideoPreviewLayer?


    override func viewDidLoad() {
        super.viewDidLoad()

        //self.view.backgroundColor = UIColor.redColor()

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

    // https://gist.github.com/franklinho/b43cc2c6c0c3ecd6a9d0

    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {

        print("url is \(outputFileURL)")
        var filename = "CroppedVideo2345"
        //let croppedVideoPath =  "crop3.mp4"

        let timestamp = String(NSDate().timeIntervalSince1970)
        //let outputFilePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("\(timestamp)movie153.mov")

        let croppedVideoPath : String = String(format: "%@%@", NSTemporaryDirectory(), "output4\(timestamp).mov")


        //var asset : AVAsset = AVAsset.assetWithURL(outputFileURL) as AVAsset
        let asset : AVURLAsset = AVURLAsset(URL: outputFileURL, options: nil)


        // Make a thumbnail

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true


        let time = CMTimeMakeWithSeconds(0.5, 1000)
        var actualTime = kCMTimeZero
        var thumbnail : CGImageRef?
        do {
            thumbnail = try imageGenerator.copyCGImageAtTime(time, actualTime: &actualTime)
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }

        let uiImage = UIImage(CGImage: thumbnail!)
        let imageData: NSData = UIImageJPEGRepresentation(uiImage, 0.8)!


        let imagePreviewPath : String = String(format: "%@%@", NSTemporaryDirectory(), "output4\(timestamp).mov")
        imageData.writeToFile(imagePreviewPath, atomically: true)

        let clip = Clip(previewPath: imagePreviewPath)
        Clip.clips.append(clip)

        collectionView.reloadData()










































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

