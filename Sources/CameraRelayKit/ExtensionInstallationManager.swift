//
//  ExtensionManager.swift
//  VideoCue
//
//  Created by Chris Hinkle on 9/19/23.
//

import Foundation
import AVFoundation
import SystemExtensions
import Observation
import os.log

@Observable
public class ExtensionInstallationManager:NSObject
{
    private var discoverySession:AVCaptureDevice.DiscoverySession!
    private var devicesObserver:NSKeyValueObservation!
    
    let configuration:ConfigurationProvider
    let logger:Logger
    public init( configuration:ConfigurationProvider, logger:Logger )
    {
        self.configuration = configuration
        self.logger = logger
        super.init( )
        discoverySession = .init( deviceTypes:AVCaptureDevice.DeviceType.cameras, mediaType:.video, position:.unspecified )
        devicesObserver = discoverySession.observe( \.devices )
        {
            [weak self] session, change in
            guard let self = self else
            {
                return
            }
            checkIfInstalled( )
        }
        checkIfInstalled( )
    }
    
    func checkIfInstalled( )
    {
        if discoverySession.devices.isInstalled( uuidString:configuration.deviceID.uuidString )
        {
            status = .installed
        }
    }
    
    func checkIfUninstalled( )
    {
        if !discoverySession.devices.isInstalled( uuidString:configuration.deviceID.uuidString )
        {
            status = .notInstalled
        }
    }
    
    public enum Status:String,CustomStringConvertible
    {
        case notInstalled = "Not installed"
        case installing = "Installing…"
        case needsApproval = "Needs approval…"
        case installRequestFailed = "Install failed"
        case installRequestSuccessful = "Install successful"
        case installRequestNeedsReboot = "Install successful, reboot required"
        case installed = "Installed"
        case uninstalling = "Uninstalling…"
        case uninstallRequestFailed = "Uninstall failed"
        case uninstallRequestSuccessful = "Uninstall successful"
        case uninstallRequestNeedsReboot = "Uninstall successful, reboot required"
        
        public var description:String
        {
            rawValue
        }
    }
    
    public var status:Status = .notInstalled
    
    var installRequestIdentifier:String?
    var uninstallRequestIdentifier:String?

    public func install( )
    {
        status = .installing
        guard let extensionIdentifier = Self._extenstionBundle( ).bundleIdentifier else
        {
            fatalError( )
        }
        let activationRequest = OSSystemExtensionRequest.activationRequest( forExtensionWithIdentifier:extensionIdentifier, queue:.main )
        activationRequest.delegate = self
        installRequestIdentifier = activationRequest.identifier
        OSSystemExtensionManager.shared.submitRequest( activationRequest )
    }
    
    public func uninstall( )
    {
        status = .uninstalling
        guard let extensionIdentifier = Self._extenstionBundle( ).bundleIdentifier else
        {
            fatalError( )
        }
        let dectivationRequest = OSSystemExtensionRequest.deactivationRequest( forExtensionWithIdentifier:extensionIdentifier, queue:.main )
        dectivationRequest.delegate = self
        uninstallRequestIdentifier = dectivationRequest.identifier
        OSSystemExtensionManager.shared.submitRequest( dectivationRequest )
    }
    
    public func restart( )
    {
        let url = URL( fileURLWithPath:Bundle.main.resourcePath! )
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        exit(0)
    }
}

extension ExtensionInstallationManager:OSSystemExtensionRequestDelegate
{
    public func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction
    {
        return .replace
    }
    
    public func requestNeedsUserApproval( _ request: OSSystemExtensionRequest )
    {
        status = .needsApproval
    }
    
    public func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result )
    {
        if request.identifier == installRequestIdentifier
        {
            installRequestIdentifier = nil
            switch result
            {
            case .completed:
                status = .installRequestSuccessful
            case .willCompleteAfterReboot:
                status = .installRequestNeedsReboot
            @unknown default:
                break
            }
            
            checkIfInstalled( )
            return
        }
        
        
        if request.identifier == uninstallRequestIdentifier
        {
            uninstallRequestIdentifier = nil
            switch result
            {
            case .completed:
                status = .uninstallRequestSuccessful
            case .willCompleteAfterReboot:
                status = .installRequestNeedsReboot
            @unknown default:
                break
            }
            
            checkIfUninstalled( )
            return
        }
    }
    
    public func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error)
    {
        if let osExtensionError = error as? OSSystemExtensionError
        {
            logger.error( "\( osExtensionError.code.description )" )
        }
        else
        {
            logger.error( "\( error.localizedDescription )" )
        }
        
        
        if request.identifier == installRequestIdentifier
        {
            installRequestIdentifier = nil
            status = .installRequestFailed
            return
        }
        
        if request.identifier == uninstallRequestIdentifier
        {
            uninstallRequestIdentifier = nil
            status = .uninstallRequestFailed
            return
        }
    }
}

extension ExtensionInstallationManager
{
    private class func _extenstionBundle( ) -> Bundle
    {
        let extensionDirectoryURL = URL.init(filePath:"Contents/Library/SystemExtensions", relativeTo:Bundle.main.bundleURL )
        let extensionURLs:[URL]
        do {
            extensionURLs = try FileManager.default.contentsOfDirectory(at:extensionDirectoryURL, includingPropertiesForKeys:nil, options: .skipsHiddenFiles )
        }
        catch let error
        {
            fatalError( "Failed to fget the contents of \( extensionDirectoryURL.absoluteString ): \( error.localizedDescription )" )
        }
        
        guard let extensionURL = extensionURLs.first else
        {
            fatalError( "Failed to find any system extensions")
        }
        
        guard let exensionBundle = Bundle( url:extensionURL ) else
        {
            fatalError( "failed to create a bundle with url \( extensionURL.absoluteString )" )
        }
        return exensionBundle
    }
}

extension OSSystemExtensionError.Code:CustomStringConvertible
{
    public var description: String
    {
        switch self
        {
        case .authorizationRequired:
            return "authorizationRequired \( rawValue )"
        case .codeSignatureInvalid:
            return "codeSignatureInvalid \( rawValue )"
        case .duplicateExtensionIdentifer:
            return "duplicateExtensionIdentifer \( rawValue )"
        case .extensionMissingIdentifier:
            return "extensionMissingIdentifier \( rawValue )"
        case .extensionNotFound:
            return "extensionNotFound \( rawValue )"
        case .forbiddenBySystemPolicy:
            return "forbiddenBySystemPolicy \( rawValue )"
        case .missingEntitlement:
            return "missingEntitlement \( rawValue )"
        case .requestCanceled:
            return "requestCanceled \( rawValue )"
        case .requestSuperseded:
            return "requestSuperseded \( rawValue )"
        case .unknown:
            return "unknown \( rawValue )"
        case .unknownExtensionCategory:
            return "unknownExtensionCategory \( rawValue )"
        case .unsupportedParentBundleLocation:
            return "unsupportedParentBundleLocation \( rawValue )"
        case .validationFailed:
            return "validationFailed \( rawValue )"
        default:
            return "unknown \( rawValue )"
        }
    }
}

extension Array<AVCaptureDevice>
{
    func isInstalled( uuidString:String ) -> Bool
    {
        contains( where:{ $0.uniqueID == uuidString } )
    }
}
