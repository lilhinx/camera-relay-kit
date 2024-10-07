//
//  LocalSourceStreamProvider.swift
//  Hyssop
//
//  Created by Chris Hinkle on 10/21/23.
//

import Foundation
import CoreMedia
import CoreMediaIO
import AVFoundation
import Cocoa
import os.log
import AsyncAlgorithms


public extension CMIOObjectPropertyAddress {
    init(_ selector: CMIOObjectPropertySelector,
         _ scope: CMIOObjectPropertyScope = .anyScope,
         _ element: CMIOObjectPropertyElement = .anyElement) {
        self.init(mSelector: selector, mScope: scope, mElement: element)
    }
}

public extension CMIOObjectPropertyScope {
    /// The CMIOObjectPropertyScope for properties that apply to the object as a whole.
    /// All CMIOObjects have a global scope and for some it is their only scope.
  
    
    /// The wildcard value for CMIOObjectPropertyScopes.
    static let anyScope = CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard)
    
    /// The CMIOObjectPropertyScope for properties that apply to the input signal paths of the CMIODevice.
    static let deviceInput = CMIOObjectPropertyScope(kCMIODevicePropertyScopeInput)
    
    /// The CMIOObjectPropertyScope for properties that apply to the output signal paths of the CMIODevice.
    static let deviceOutput = CMIOObjectPropertyScope(kCMIODevicePropertyScopeOutput)
    
    /// The CMIOObjectPropertyScope for properties that apply to the play through signal paths of the CMIODevice.
    static let devicePlayThrough = CMIOObjectPropertyScope(kCMIODevicePropertyScopePlayThrough)
}

public extension CMIOObjectPropertyElement {
    /// The CMIOObjectPropertyElement value for properties that apply to the master element or to the entire scope.
    //static let master = CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster)
//    static let main = CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
    /// The wildcard value for CMIOObjectPropertyElements.
    static let anyElement = CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
}



open class LocalSourceStreamProvider:NSObject, ObservableObject
{
    public enum Problem:Error
    {
        case notImplemented
    }
    
    func makeDevicesVisible( )
    {
        var prop = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
        var allow : UInt32 = 1
        let dataSize : UInt32 = 4
        let zero : UInt32 = 0
        CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop, zero, nil, dataSize, &allow)
    }
    
    

    func getCMIODevice( uid: String) -> CMIOObjectID?
    {
        var dataSize: UInt32 = 0
        var devices = [CMIOObjectID]()
        var dataUsed: UInt32 = 0
        var opa = CMIOObjectPropertyAddress(CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices), .global, .main)
        CMIOObjectGetPropertyDataSize(CMIOObjectPropertySelector(kCMIOObjectSystemObject), &opa, 0, nil, &dataSize);
        let nDevices = Int(dataSize) / MemoryLayout<CMIOObjectID>.size
        devices = [CMIOObjectID](repeating: 0, count: Int(nDevices))
        CMIOObjectGetPropertyData(CMIOObjectPropertySelector(kCMIOObjectSystemObject), &opa, 0, nil, dataSize, &dataUsed, &devices);
        for deviceObjectID in devices {
            opa.mSelector = CMIOObjectPropertySelector(kCMIODevicePropertyDeviceUID)
            CMIOObjectGetPropertyDataSize(deviceObjectID, &opa, 0, nil, &dataSize)
            var name: CFString = "" as NSString
            //CMIOObjectGetPropertyData(deviceObjectID, &opa, 0, nil, UInt32(MemoryLayout<CFString>.size), &dataSize, &name);
            CMIOObjectGetPropertyData(deviceObjectID, &opa, 0, nil, dataSize, &dataUsed, &name);
            if String(name) == uid {
                return deviceObjectID
            }
        }
        return nil
    }

    func getInputStreams(deviceId: CMIODeviceID) -> [CMIOStreamID]
    {
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        var opa = CMIOObjectPropertyAddress(CMIOObjectPropertySelector(kCMIODevicePropertyStreams), .global, .main)
        CMIOObjectGetPropertyDataSize(deviceId, &opa, 0, nil, &dataSize);
        let numberStreams = Int(dataSize) / MemoryLayout<CMIOStreamID>.size
        var streamIds = [CMIOStreamID](repeating: 0, count: numberStreams)
        CMIOObjectGetPropertyData(deviceId, &opa, 0, nil, dataSize, &dataUsed, &streamIds)
        return streamIds
    }
    
    public let configuration:ConfigurationProvider
    let logger:Logger
    public init( configuration:ConfigurationProvider, logger:Logger )
    {
        self.configuration = configuration
        self.logger = logger
        super.init( )
        registerForDeviceNotifications( )
        makeDevicesVisible( )
        connectToCamera( )
    }
    
    
    open func prepare( ) async throws
    {
        
    }

    
    public func enqueue( _ buffer: CMSampleBuffer )
    {
        guard let queue = sinkQueue else
        {
            return
        }
        
        guard CMSimpleQueueGetCount( queue ) < CMSimpleQueueGetCapacity( queue ) else
        {
            print("error enqueuing")
            return
        }
        
        let pointerRef = UnsafeMutableRawPointer(Unmanaged.passRetained(buffer).toOpaque())
        CMSimpleQueueEnqueue( queue, element: pointerRef )
    }
    
    
    
    public let noVideoImage : CGImage = NSImage(
        systemSymbolName: "video.slash",
        accessibilityDescription: "Image to indicate no video feed available"
    )!.cgImage( forProposedRect: nil, context: nil, hints: nil )! // OK to fail if this isn't available.
    
    var sourceStream: CMIOStreamID?
    var sinkStream: CMIOStreamID?
    var sinkQueue: CMSimpleQueue?
    private let readyToEnqueue = true
    private var enqueued = false
   
    
    func connectToCamera( )
    {
        guard let device = AVCaptureDevice.init( uniqueID:configuration.deviceID.uuidString ) else
        {
            return
        }
        
        guard let deviceObjectId = getCMIODevice( uid:device.uniqueID ) else
        {
            return
        }
        
        let streamIds = getInputStreams( deviceId:deviceObjectId )
        if streamIds.count == 2
        {
            sinkStream = streamIds[1]
            initSink( deviceId:deviceObjectId, sinkStream:streamIds[1] )
        }
        
        if let firstStream = streamIds.first
        {
            sourceStream = firstStream
        }
    }
    
    func initSink( deviceId:CMIODeviceID, sinkStream:CMIOStreamID )
    {
        let pointerQueue = UnsafeMutablePointer<Unmanaged<CMSimpleQueue>?>.allocate( capacity:1 )
        defer
        {
            pointerQueue.deallocate( )
        }
       
        
        let donk = Zoink( )
        let pointerRef = UnsafeMutableRawPointer( Unmanaged.passUnretained( donk ).toOpaque( ) )
        let result = CMIOStreamCopyBufferQueue( sinkStream, {
            ( sinkStream:CMIOStreamID, buf: UnsafeMutableRawPointer?, refcon: UnsafeMutableRawPointer?) in

        }, pointerRef, pointerQueue )
       
        if result != 0 
        {
            print("error starting sink")
        } 
        else
        {
            if let queue = pointerQueue.pointee 
            {
                self.sinkQueue = queue.takeUnretainedValue()
            }
            let resultStart = CMIODeviceStartStream( deviceId, sinkStream ) == 0
            if resultStart
            {
                print("initSink started")
            } 
            else
            {
                print("initSink error startstream")
            }
        }
    }
    
    class Zoink
    {
        func florb( )
        {
            
        }
    }
    
    func registerForDeviceNotifications( )
    {
        let name:NSNotification.Name = .AVCaptureDeviceWasConnected
        NotificationCenter.default.addObserver( forName:name, object: nil, queue: nil )
        {
            [weak self]( notif ) -> Void in
            if self?.sourceStream == nil
            {
                self?.connectToCamera( )
            }
        }
    }
}
