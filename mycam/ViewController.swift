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
import CoreMedia

// Clip model holds the the individual clips that we will combine to make movie
class Clip {

    static var clips = Array<Clip>()
    static var totalDuration:Float64 = 0
    var previewPath:String!
    var croppedVideoPath:String!
    var duration:Float64

    init (previewPath: String, croppedVideoPath: String, duration: Float64 ) {
        self.previewPath = previewPath
        self.croppedVideoPath = croppedVideoPath
        self.duration = duration
    }

    static func updateClipDuration(){
        Clip.totalDuration = 0
        for clip in Clip.clips{
            Clip.totalDuration = Clip.totalDuration + clip.duration
        }
    }

}

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, UICollectionViewDelegate, UICollectionViewDataSource{

    var movieFileOutput: AVCaptureMovieFileOutput?
    var sessionQueue: dispatch_queue_t!
    var backgroundRecordId: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var timer:NSTimer = NSTimer()
    var startTime = NSTimeInterval()

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var countDown: UIProgressView!

    override func viewDidLoad() {
        super.viewDidLoad()

        countDown.progress = 0

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

    // update the countDown progress bar UI
    func updateCountDown(){
        let maxTime:Float64 = 9
        let currentTime = NSDate.timeIntervalSinceReferenceDate()
        var elapsedTime: NSTimeInterval = currentTime - startTime
        let agregateDuration = Float64(elapsedTime) + Clip.totalDuration
        countDown.progress = Float(agregateDuration / maxTime)
    }

    @IBAction func pressRecordButton(sender: AnyObject) {

        // Check to see if total clip durtion is under 9s
        Clip.updateClipDuration()
        if Clip.totalDuration < Float64(9){
            self.view.backgroundColor = UIColor.redColor()
            if (!timer.valid) {
                let aSelector : Selector = "updateCountDown"
                timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: aSelector, userInfo: nil, repeats: true)
                startTime = NSDate.timeIntervalSinceReferenceDate()
            }


            dispatch_async(self.sessionQueue, {
                if !self.movieFileOutput!.recording{
                    print("start recording")
                    let timestamp = String(NSDate().timeIntervalSince1970)
                    let outputFilePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("\(timestamp)clip.mov")
                    print("outputFilePath is \(outputFilePath)")
                    self.movieFileOutput!.startRecordingToOutputFileURL( outputFilePath, recordingDelegate: self)
                }
            })
        }



    }

    @IBAction func releaseRecordButton(sender: AnyObject) {
        self.view.backgroundColor = UIColor.whiteColor()
        timer.invalidate()

        if self.movieFileOutput!.recording{
            print("stop recording")
            self.movieFileOutput!.stopRecording()
        }
    }

    @IBAction func exportButton(sender: AnyObject) {

        var mutableComposition: AVMutableComposition = AVMutableComposition()

        var time: CMTime = kCMTimeZero
        var size: CGSize = CGSizeZero

        // Make our track
        var videoCompositionTrack: AVMutableCompositionTrack = mutableComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)

        for clip in Clip.clips{

            // Make our asset
            var url = NSURL(fileURLWithPath: clip.croppedVideoPath)
            var asset = AVAsset(URL: url)

            // Make our video composition track
            var videoAssetTrack: AVAssetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0]

            var clipRange: CMTimeRange = CMTimeRangeMake(kCMTimeZero, kCMTimeZero)

            // check that the total duration wont be over 9s
            // if it it limit the range of the track to max  sure maximum expoted clip won't exceed 9s
            if CMTimeGetSeconds(time + videoAssetTrack.timeRange.duration) > 2{
                clipRange = CMTimeRangeMake(kCMTimeZero, (CMTimeMakeWithSeconds(9, 600) - videoAssetTrack.timeRange.duration))
            } else {
                print("track time is less than 2s")
                clipRange = CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration)
            }

            // Add the AVAssetTrack to the AVVideoComposition
            do {
                try videoCompositionTrack.insertTimeRange(clipRange, ofTrack: videoAssetTrack, atTime: time)
            }
            catch let error as NSError {
                print("There was an error")
                print(error)
            }

            time = CMTimeAdd(time, videoAssetTrack.timeRange.duration)
            if CGSizeEqualToSize(size, CGSizeZero) {
                size = videoAssetTrack.naturalSize
            }


        }

        // Form the export path
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .ShortStyle
        let date = dateFormatter.stringFromDate(NSDate())
        let savePath = (documentDirectory as NSString).stringByAppendingPathComponent("mergeVideo-\(date).mov")
        let export_url = NSURL(fileURLWithPath: savePath)

        // Create Exporter
        guard let exporter = AVAssetExportSession(asset: mutableComposition, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = export_url
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true

        // Perform the Export
        exporter.exportAsynchronouslyWithCompletionHandler() {
            dispatch_async(dispatch_get_main_queue()) { _ in
                self.exportDidFinish(exporter)
            }
        }
    }

    func exportDidFinish(session: AVAssetExportSession) {
        if session.status == AVAssetExportSessionStatus.Completed {
            let outputURL = session.outputURL
            let library = ALAssetsLibrary()
            if library.videoAtPathIsCompatibleWithSavedPhotosAlbum(outputURL) {
                library.writeVideoAtPathToSavedPhotosAlbum(outputURL, completionBlock: { (assetURL:NSURL!, error:NSError!) -> Void in
                    var title = ""
                    var message = ""
                    if error != nil {
                        title = "Error"
                        message = "Failed to save video"
                    } else {
                        title = "Success"
                        message = "Video saved"
                    }
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                })
            }
        } else {
            print("session.status not complete")
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! CollectionViewCell
        let previewPath = Clip.clips[indexPath.row].previewPath
        let preview = UIImage(contentsOfFile: previewPath)
        let duration = Double(round(Clip.clips[indexPath.row].duration*10)/10)
        cell.cellTititle.text = "\(duration)s"
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

    // Process the clip to make it square
    // https://gist.github.com/franklinho/b43cc2c6c0c3ecd6a9d0
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {

        // Make the url where
        var filename = "croppedClip"
        let timestamp = String(NSDate().timeIntervalSince1970)
        let croppedVideoPath : String = String(format: "%@%@", NSTemporaryDirectory(), "\(filename)\(timestamp).mov")

        // Make the asset from the file at the url
        let asset : AVURLAsset = AVURLAsset(URL: outputFileURL, options: nil)

        // Initialise the composition
        var composition : AVMutableComposition = AVMutableComposition()
        composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))

        // Create Track
        var clipVideoTrack : AVAssetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack

        // Create video composition
        var videoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTimeMake(1, 60)
        videoComposition.renderSize = CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.height)

        // Create instruction
        var instruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30))

        // Setup transformation
        var transformer: AVMutableVideoCompositionLayerInstruction =
            AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)


        var t1: CGAffineTransform = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, -(clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height)/2 )
        var t2: CGAffineTransform = CGAffineTransformRotate(t1, CGFloat(M_PI_2))

        var finalTransform: CGAffineTransform = t2

        transformer.setTransform(finalTransform, atTime: kCMTimeZero)

        instruction.layerInstructions = NSArray(object: transformer) as! [AVVideoCompositionLayerInstruction]
        videoComposition.instructions = NSArray(object: instruction) as! [AVVideoCompositionInstructionProtocol]

        // Create exporter
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


                let imagePreviewPath : String = String(format: "%@%@", NSTemporaryDirectory(), "output4\(timestamp).jpg")
                imageData.writeToFile(imagePreviewPath, atomically: true)

                print(asset.duration)
                print("seconds = \(CMTimeGetSeconds(asset.duration))")
                let clipDuration = CMTimeGetSeconds(asset.duration)
                let clip = Clip(previewPath: imagePreviewPath, croppedVideoPath: croppedVideoPath, duration: clipDuration)
                Clip.clips.append(clip)
                Clip.updateClipDuration()
                print("Clip.totalDuration is \(Clip.totalDuration)")
                
                self.collectionView.reloadData()

            }

        })

    }
}

