//
//  ExtensionConfigurationProvider.swift
//  
//
//  Created by Chris Hinkle on 10/21/23.
//

import Foundation
import CoreMedia
import CoreMediaIO
import CoreVideo

public protocol ConfigurationProvider
{
    var manufacturer:String{ get }
    var deviceName:String{ get }
    var deviceModel:String{ get }
    var deviceID:UUID{ get }
    var sourceName:String{ get }
    var sourceID:UUID{ get }
    var sinkName:String{ get }
    var sinkID:UUID{ get }
    var frameRate:Int{ get }
    var frameRateScaleRange:Range<Float>{ get }
    var width:Int{ get }
    var height:Int{ get }
    var codecType:OSType{ get }
}

extension ConfigurationProvider
{
    public var maxFrameDuration:CMTime
    {
        CMTime( value:1, timescale:Int32( frameRate ) )
    }
    
    public var minFrameDuration:CMTime
    {
        CMTime( value:1, timescale:Int32( frameRate ) )
    }
    
    public var dimensions:CMVideoDimensions
    {
        CMVideoDimensions( width:Int32( width ), height:Int32( height ) )
    }
    
    public var format:CMFormatDescription
    {
        var fmt:CMFormatDescription!
        CMVideoFormatDescriptionCreate( allocator:kCFAllocatorDefault, codecType:codecType, width:dimensions.width, height:dimensions.height, extensions:nil, formatDescriptionOut:&fmt )
        return fmt
    }
    
    public func bufferPool( ) -> CVPixelBufferPool
    {
        var pool:CVPixelBufferPool!
        let pixelBufferAttributes: NSDictionary = [
            kCVPixelBufferWidthKey: dimensions.width,
            kCVPixelBufferHeightKey: dimensions.height,
            kCVPixelBufferPixelFormatTypeKey: format.mediaSubType,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as NSDictionary
        ]
        CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, pixelBufferAttributes, &pool)
        return pool
    }
    
    public var streamFormat:CMIOExtensionStreamFormat
    {
        CMIOExtensionStreamFormat.init( formatDescription:format, maxFrameDuration:maxFrameDuration , minFrameDuration:minFrameDuration, validFrameDurations:nil )
    }
    
    public func buffer( ) -> FrameBuffer
    {
        return FrameBuffer( format:format, bufferPool:bufferPool( ) )
    }
    
    func frameDelay( rate:Double ) -> Duration
    {
        return .seconds( ( 1.0 / Double( frameRate ) * ( rate ) ) )
    }
}
