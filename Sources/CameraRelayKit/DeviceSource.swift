//
//  DeviceSource.swift
//  CameraExtension
//
//  Created by Chris Hinkle on 9/22/23.
//

import Foundation
import CoreMediaIO
import IOKit.audio
import os.log
import Cocoa

protocol DeviceSourceDelegate: NSObject 
{
    func bufferReceived(_ buffer:CMSampleBuffer )
}

class DeviceSource: NSObject, CMIOExtensionDeviceSource
{
    private var source:OutputStreamSource!
    private var sink:InputStreamSource!
    
    public weak var extensionDeviceSourceDelegate: DeviceSourceDelegate?
    
    private var sourceCount:Int = 0
    private var sinkCount:Int = 0
    
    var sourceRunning:Bool
    {
        sourceCount > 0
    }
    
    var sourceFrameCounter:UInt32 = 0
    
    
   
    private var buffer:FrameBuffer!
    private var buffer2:FrameBuffer!
    
   
    
   
    private(set) var device: CMIOExtensionDevice!
    let configuration:ConfigurationProvider
    init( configuration:ConfigurationProvider )
    {
        self.configuration = configuration
        super.init( )
        self.buffer = .init( format:configuration.format, bufferPool:configuration.bufferPool( ) )
        self.buffer2 = .init( format:configuration.format, bufferPool:configuration.bufferPool( ) )
        
        self.device = CMIOExtensionDevice( localizedName:configuration.deviceName , deviceID:configuration.deviceID, legacyDeviceID:nil, source:self )
        source = OutputStreamSource( localizedName:configuration.sourceName, streamID:configuration.sourceID, streamFormat:configuration.streamFormat, maxFrameDuration:configuration.maxFrameDuration, delegate:self )
        sink = InputStreamSource( localizedName:configuration.sinkName, streamID:configuration.sinkID, streamFormat:configuration.streamFormat, maxFrameDuration:configuration.maxFrameDuration, delegate:self )

    }
    
    func prepare( ) async throws
    {
//        try await videoRender.prepare( )
        try device.addStream( source.stream )
        try device.addStream( sink.stream )
    }
    
   
        
    
    var availableProperties: Set<CMIOExtensionProperty> {
        
        return [ .deviceTransportType, .deviceModel ]
    }
    
    func deviceProperties( forProperties properties:Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties 
    {
        
        let deviceProperties = CMIOExtensionDeviceProperties( dictionary:[ : ] )
        if properties.contains( .deviceTransportType )
        {
            deviceProperties.transportType = kIOAudioDeviceTransportTypeVirtual
        }
        
        if properties.contains( .deviceModel )
        {
            deviceProperties.model = configuration.deviceModel
        }
        
        return deviceProperties
    }
    
    func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws 
    {
        // Handle settable properties here.
    }
    
    
//    let videoRender:VideoCompositionImageRenderer = .init( )
    
    
//    func getSampleBuffer( presentationTime:CMTime ) async throws -> CMSampleBuffer
//    {
//        let pixelBuffer = try buffer.getBuffer( )
//        let image = try await videoRender.render( time:presentationTime )
//        try pixelBuffer.draw( image:image )
//        return try buffer.sampleBuffer( for:pixelBuffer, presentationTime:presentationTime )
//    }
//     
    /*
    func processSource( )
    {
        Task
        {
            do
            {
                sourceFrameCounter += 1
               
                let presentationTime = CMClockGetTime( CMClockGetHostTimeClock( ) )
                let sampleBuffer = try await getSampleBuffer( presentationTime:presentationTime )
                
                if let extensionDeviceSourceDelegate = self.extensionDeviceSourceDelegate
                {
                    extensionDeviceSourceDelegate.bufferReceived( sampleBuffer )
                }
                else
                {
                    source.stream.send( sampleBuffer, discontinuity:[ ], hostTimeInNanoseconds: UInt64( presentationTime.seconds * Double( NSEC_PER_SEC ) ) )
                }
            }
            catch
            {
                print( error.localizedDescription )
                
                if let frameBufferProblem = error as? FrameBuffer.Problem
                {
                    switch frameBufferProblem
                    {
                    case .couldNotCreateSampleBuffer:
                        logger.error( "couldNotCreateSampleBuffer" )
                    case .outOfPixelBuffers:
                        logger.error( "outOfPixelBuffers" )
                    case .pixelBufferNotCreated:
                        logger.error( "pixelBufferNotCreated" )
                    }
                }
                
                logger.error( "processSource error" )
            }
        }
    }
     */
    
    var lastTimingInfo = CMSampleTimingInfo( )
    var sinkStarted = false
    
    func consumeBuffer( _ client:CMIOExtensionClient )
    {
        guard sinkStarted else
        {
            return
        }
        
        sink.stream.consumeSampleBuffer( from: client )
        {
            sbuf, seq, discontinuity, hasMoreSampleBuffers, err in
            if sbuf != nil 
            {
                self.lastTimingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())
                let output: CMIOExtensionScheduledOutput = CMIOExtensionScheduledOutput(sequenceNumber: seq, hostTimeInNanoseconds: UInt64(self.lastTimingInfo.presentationTimeStamp.seconds * Double(NSEC_PER_SEC)))
                if self.sourceCount > 0
                {
                    self.source.stream.send( sbuf!, discontinuity: [], hostTimeInNanoseconds: UInt64(sbuf!.presentationTimeStamp.seconds * Double(NSEC_PER_SEC)))
                }
                self.sink.stream.notifyScheduledOutputChanged(output)
            }
            self.consumeBuffer(client)
        }
    }
   
}

extension DeviceSource:OutputStreamSourceDelegate
{
    func startSource( ) throws
    {
        sourceCount += 1
        
    }
    
    func stopSource( ) throws 
    {
        if sourceCount > 1
        {
            sourceCount -= 1
        }
        else
        {
            sourceCount = 0
        }
    }
}

extension DeviceSource:InputStreamSourceDelegate
{
    func startSink( client:CMIOExtensionClient ) throws
    {
        sinkCount += 1
        sinkStarted = true
        consumeBuffer(client)
    }
    
    func stopSink( ) throws
    {
        sinkStarted = false
        if sinkCount > 1 
        {
            sinkCount -= 1
        }
        else 
        {
            sinkCount = 0
        }
    }
}
