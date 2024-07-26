# camera-relay-kit
A collection of convenience code around including a Camera Extension in a macOS app

1. Create a new camera extension target in your app.
2. Create a class or struct which conforms to ConfigurationProvider for both your app and your camera extension to share.

```
import Foundation
import CameraRelayKit
import AVFoundation

public struct MyCoolAppConfig:ConfigurationProvider
{
	public let manufacturer:String = "MyCoolApp.app"
	public let deviceName:String = "MyCoolApp"
	public let deviceModel:String = "MyCoolApp"
	public let deviceID:UUID = .init( uuidString:"[ INSERT UNIQUE UUID STRING HERE ]" )!
	
	
	public let sourceName:String = "MyCoolApp.videoSource"
	public let sourceID:UUID = .init( uuidString:"[ INSERT UNIQUE UUID STRING HERE ]" )!
	
	public let sinkName:String = "MyCoolApp.videoSink"
	public let sinkID:UUID = .init( uuidString:"[ INSERT UNIQUE UUID STRING HERE ]" )!
	
	public let frameRate:Int = 24
	public let frameRateScaleRange:Range<Float> = .init( uncheckedBounds:( lower:0.25, upper:4.0 ) )
	
	public let width:Int = 1920
	public let height:Int = 1080
	public let codecType:OSType = kCVPixelFormatType_32BGRA
	
	public init( ){ }
}
```

3. Use the following code to in the main.swift file for the camera extension target.

```
import Foundation
import CoreMediaIO
import CameraRelayKit
import os.log

let logger = Logger( subsystem:"com.example.mycoolapp", category:"Extension" )

struct

let providerSource = ProviderSource( configuration:MyCoolAppConfig( ) )
Task
{
	do
	{
		try await providerSource.prepare( )
		logger.error( "provider prepared" )
		CMIOExtensionProvider.startService( provider:providerSource.provider )
		logger.error( "service started" )
		
	}
	catch
	{
		logger.error( "could not prepare provider source" )
//        fatalError( error.localizedDescription )
	}
}

CFRunLoopRun( )
```

4. Create a class which inherits from `LocalSourceStreamProvider`, and enqueue frames using the `public func enqueue( _ buffer: CMSampleBuffer )` method


5. Manage installation of the camera extension like so (SwiftUI):

```

import SwiftUI
import CameraRelayKit

struct InstallButtonView:View
{
	let extensionManager:ExtensionInstallationManager = .shared

	func installIfNeeded( )
	{
		if extensionManager.status == .notInstalled
		{
			extensionManager.install( )
		}
	}
	
	var body: some View
	{
		Button( action:installIfNeeded )
		{
			Text( extensionManager.status.description )
		}
	}

}

```
