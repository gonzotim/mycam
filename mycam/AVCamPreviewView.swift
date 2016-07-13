////
////  AVCamPreviewView.swift
////  mycam
////
////  Created by Tim Sutcliffe on 7/11/16.
////  Copyright © 2016 Tim Sutcliffe. All rights reserved.
////
//
//import Foundation
//import UIKit
//import AVFoundation
//
//
//class AVCamPreviewView: UIView{
//
//    var session: AVCaptureSession? {
//        get{
//            return (self.layer as! AVCaptureVideoPreviewLayer).session;
//        }
//        set(session){
//            (self.layer as! AVCaptureVideoPreviewLayer).session = session;
//        }
//    };
//
//
//
//    override class func layerClass() ->AnyClass{
//        return AVCaptureVideoPreviewLayer.self;
//    }
//
//
//
//
//
//
//
//
//
//}