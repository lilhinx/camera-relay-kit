//
//  AVCaptureDevice.DeviceType+Cameras.swift
//
//
//  Created by Chris Hinkle on 10/21/23.
//

import Foundation
import AVFoundation

extension AVCaptureDevice:Identifiable
{
    public var id:String
    {
        return uniqueID
    }
}


extension AVCaptureDevice.DeviceType
{
    public static var cameras: [AVCaptureDevice.DeviceType]
    {
        return [ .builtInWideAngleCamera, .continuityCamera, .external, .deskViewCamera  ]
    }
}
