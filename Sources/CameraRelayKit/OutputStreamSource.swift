//
//  StreamSource.swift
//  CameraExtension
//
//  Created by Chris Hinkle on 9/23/23.
//

import Foundation
import CoreMediaIO
import os.log

protocol OutputStreamSourceDelegate:NSObjectProtocol
{
    func startSource( ) throws
    func stopSource( ) throws
}

class OutputStreamSource: NSObject, CMIOExtensionStreamSource
{
    private(set) var stream: CMIOExtensionStream!
    
    private let streamFormat: CMIOExtensionStreamFormat
    let maxFrameDuration:CMTime
    private weak var delegate:OutputStreamSourceDelegate?
    init( localizedName:String, streamID:UUID, streamFormat:CMIOExtensionStreamFormat, maxFrameDuration:CMTime, delegate:OutputStreamSourceDelegate )
    {
        self.delegate = delegate
        self.streamFormat = streamFormat
        self.maxFrameDuration = maxFrameDuration
        super.init( )
        self.stream = CMIOExtensionStream( localizedName:localizedName, streamID:streamID, direction:.source, clockType:.hostTime, source:self )
    }
    
    var formats:[CMIOExtensionStreamFormat]
    {
        return [streamFormat]
    }
    
    var activeFormatIndex: Int = 0 
    {
        didSet 
        {
            if activeFormatIndex >= 1 
            {
                os_log( .error, "Invalid index")
            }
        }
    }
    
    var availableProperties: Set<CMIOExtensionProperty>
    {
        return [ .streamActiveFormatIndex, .streamFrameDuration ]
    }
    
    func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties 
    {
        let streamProperties = CMIOExtensionStreamProperties( dictionary:[:] )
        if properties.contains( .streamActiveFormatIndex )
        {
            streamProperties.activeFormatIndex = 0
        }
        
        if properties.contains( .streamFrameDuration )
        {
            streamProperties.frameDuration = maxFrameDuration
        }
        
        return streamProperties
    }
    
    func setStreamProperties( _ streamProperties:CMIOExtensionStreamProperties ) throws
    {
        if let activeFormatIndex = streamProperties.activeFormatIndex 
        {
            self.activeFormatIndex = activeFormatIndex
        }
    }
    
    func authorizedToStartStream( for client:CMIOExtensionClient )-> Bool
    {
        return true
    }
    
    func startStream( ) throws
    {
        try delegate?.startSource( )
    }
    
    func stopStream( ) throws
    {
        try delegate?.stopSource( )
    }
}
