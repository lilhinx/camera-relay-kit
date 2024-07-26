//
//  InputStreamSource.swift
//  CameraExtension
//
//  Created by Chris Hinkle on 10/19/23.
//

import Foundation
import CoreMediaIO
import os.log

protocol InputStreamSourceDelegate:NSObjectProtocol
{
    func startSink( client:CMIOExtensionClient ) throws
    func stopSink( ) throws
}

class InputStreamSource: NSObject, CMIOExtensionStreamSource
{
    private(set) var stream: CMIOExtensionStream!
    
    private let _streamFormat: CMIOExtensionStreamFormat
    
    private weak var delegate:InputStreamSourceDelegate?
    let maxFrameDuration:CMTime
    init( localizedName:String, streamID:UUID, streamFormat:CMIOExtensionStreamFormat, maxFrameDuration:CMTime, delegate:InputStreamSourceDelegate )
    {
        self.delegate = delegate
        self._streamFormat = streamFormat
        self.maxFrameDuration = maxFrameDuration
        super.init()
        self.stream = CMIOExtensionStream( localizedName:localizedName, streamID:streamID, direction: .sink, clockType: .hostTime, source: self )
    }
    
    var formats: [CMIOExtensionStreamFormat] {
        
        return [_streamFormat]
    }
    
    var activeFormatIndex: Int = 0 {
        
        didSet {
            if activeFormatIndex >= 1 {
                os_log(.error, "Invalid index")
            }
        }
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        
        return [.streamActiveFormatIndex, .streamFrameDuration, .streamSinkBufferQueueSize, .streamSinkBuffersRequiredForStartup, .streamSinkBufferUnderrunCount, .streamSinkEndOfData]
    }

    var client: CMIOExtensionClient?
    func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
        let streamProperties = CMIOExtensionStreamProperties(dictionary: [:])
        if properties.contains(.streamActiveFormatIndex) {
            streamProperties.activeFormatIndex = 0
        }
        if properties.contains(.streamFrameDuration) 
        {
            streamProperties.frameDuration = maxFrameDuration
        }
        if properties.contains(.streamSinkBufferQueueSize) {
            streamProperties.sinkBufferQueueSize = 1
        }
        if properties.contains(.streamSinkBuffersRequiredForStartup) {
            streamProperties.sinkBuffersRequiredForStartup = 1
        }
        return streamProperties
    }
    
    func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
        
        if let activeFormatIndex = streamProperties.activeFormatIndex {
            self.activeFormatIndex = activeFormatIndex
        }
        
    }
    
    func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
        
        // An opportunity to inspect the client info and decide if it should be allowed to start the stream.
        self.client = client
        return true
    }
    
    func startStream( ) throws
    {
        guard let client = client else
        {
            return
        }
        try delegate?.startSink( client:client )
    }
    
    func stopStream( ) throws
    {
        try delegate?.stopSink( )
    }
}
