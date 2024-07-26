//
//  ProviderSource.swift
//  CameraExtension
//
//  Created by Chris Hinkle on 9/21/23.
//

import Foundation
import CoreMediaIO


public class ProviderSource:NSObject, CMIOExtensionProviderSource
{
    public private(set) var provider:CMIOExtensionProvider!
    let deviceSource:DeviceSource
    
    private let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter( )
    private var notificationListenerStarted = false
    
    let configuration:ConfigurationProvider
    public init( configuration:ConfigurationProvider, clientQueue:DispatchQueue? = nil)
    {
        self.configuration = configuration
        deviceSource = DeviceSource( configuration:configuration )
        super.init( )
        provider = CMIOExtensionProvider( source:self, clientQueue:clientQueue )
    }
    
    public func prepare( ) async throws
    {
        try provider.addDevice( deviceSource.device )
        try await deviceSource.prepare( )
    }
    
    
    public func connect( to client:CMIOExtensionClient ) throws
    {
        
    }
    
    public func disconnect( from client:CMIOExtensionClient )
    {
        
    }
    
    public var availableProperties: Set<CMIOExtensionProperty>
    {
        return [ .providerManufacturer ]
    }
    
    public func providerProperties( forProperties properties:Set<CMIOExtensionProperty> ) throws -> CMIOExtensionProviderProperties
    {
        let providerProperties = CMIOExtensionProviderProperties( dictionary:[:] )
        if properties.contains(.providerManufacturer )
        {
            providerProperties.manufacturer = configuration.manufacturer
        }
        
        
        return providerProperties
    }
    
    public func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties ) throws 
    {
        
    }
}
