//
//  CoreMediaIOHelpers.swift
//  CameraExtension
//
//  Created by Chris Hinkle on 9/23/23.
//

import Foundation
import CoreMediaIO

extension CMIOObjectPropertyScope
{
    static let global:CMIOObjectPropertyScope = CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal)
}

extension CMIOObjectPropertySelector
{
    static let hardwareDevices:CMIOObjectPropertySelector = CMIOObjectPropertySelector( kCMIOHardwarePropertyDevices )
    static let systemObject:CMIOObjectPropertySelector = CMIOObjectPropertySelector( kCMIOObjectSystemObject)
    static let deviceUID:CMIOObjectPropertySelector = CMIOObjectPropertySelector( kCMIODevicePropertyDeviceUID )
    static let streams:CMIOObjectPropertySelector = CMIOObjectPropertySelector( kCMIODevicePropertyStreams )
    static let streamDirection:CMIOObjectPropertySelector = CMIOObjectPropertySelector( kCMIOStreamPropertyDirection )
}

extension CMIOObjectPropertyElement
{
    static let main:CMIOObjectPropertyElement = CMIOObjectPropertyElement( kCMIOObjectPropertyElementMain )
}

extension CMIOObjectPropertyAddress
{
    static let globalHardwareDevices:CMIOObjectPropertyAddress = CMIOObjectPropertyAddress( mSelector:.hardwareDevices, mScope:.global, mElement:.main )
    static let deviceUID:CMIOObjectPropertyAddress = CMIOObjectPropertyAddress( mSelector:.deviceUID, mScope:.global, mElement:.main )
    static let streams:CMIOObjectPropertyAddress = CMIOObjectPropertyAddress( mSelector:.streams, mScope:.global, mElement:.main )
    static let streamDirection:CMIOObjectPropertyAddress = CMIOObjectPropertyAddress( mSelector:.streamDirection, mScope:.global, mElement:.main )
}
