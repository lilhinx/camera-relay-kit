//
//  FrameBuffer.swift
//  CameraExtension
//
//  Created by Chris Hinkle on 9/22/23.
//

import Foundation
import CoreMedia
import CoreVideo
import os.log

public class FrameBuffer
{
    public enum Problem:Error
    {
        case couldNotCreateSampleBuffer
        case outOfPixelBuffers
        case pixelBufferNotCreated
    }
    
    let format:CMFormatDescription
    let bufferPool:CVPixelBufferPool
    
    
    public init( format:CMFormatDescription, bufferPool:CVPixelBufferPool )
    {
        self.format = format
        self.bufferPool = bufferPool
    }
    
    
    
    public func getBuffer( ) throws -> CVPixelBuffer
    {
        var pixelBuffer:CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBufferWithAuxAttributes( kCFAllocatorDefault, bufferPool, nil, &pixelBuffer ) == 0 else
        {
            throw Problem.outOfPixelBuffers
        }
        
        guard let pixelBuffer = pixelBuffer else
        {
            throw Problem.pixelBufferNotCreated
        }
        
        return pixelBuffer
    }
    
    public func sampleBuffer( for pixelBuffer:CVPixelBuffer, presentationTime:CMTime ) throws -> CMSampleBuffer
    {
        var sbuf: CMSampleBuffer!
        var timingInfo = CMSampleTimingInfo( )
        timingInfo.presentationTimeStamp = presentationTime
        let err = CMSampleBufferCreateForImageBuffer( allocator: kCFAllocatorDefault, imageBuffer:pixelBuffer, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription:format, sampleTiming: &timingInfo, sampleBufferOut: &sbuf )
        guard err == 0 else
        {
            throw Problem.couldNotCreateSampleBuffer
        }
        return sbuf
    }
    
   
}
