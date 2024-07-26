//
//  PlayerStreamProvider.swift
//
//
//  Created by Chris Hinkle on 5/14/24.
//

import Foundation
import AVFoundation
import OSLog

public class StreamProviderPlayer:AVPlayer
{
	public override func replaceCurrentItem( with item:AVPlayerItem? )
	{
		if let item = item
		{
			while item.outputs.count < 2
			{
				let output = AVPlayerItemVideoOutput( pixelBufferAttributes:nil )
				item.add( output )
			}
		}
		super.replaceCurrentItem( with:item )
	}
	
	public var displayOutput:AVPlayerItemVideoOutput?
	{
		guard let currentItem = currentItem, !currentItem.outputs.isEmpty else
		{
			return nil
		}
		
		return currentItem.outputs[ 0 ] as? AVPlayerItemVideoOutput
	}
	
	
	public var recordOutput:AVPlayerItemVideoOutput?
	{
		guard let currentItem = currentItem, currentItem.outputs.count >= 2 else
		{
			return nil
		}
		
		return currentItem.outputs[ 1 ] as? AVPlayerItemVideoOutput
	}
}

public class PlayerStreamProvider:LocalSourceStreamProvider
{
	let player:StreamProviderPlayer
	let renderQueue:DispatchQueue = .init( label:"renderoutput" )
	public init( player:StreamProviderPlayer, configuration:ConfigurationProvider, logger:Logger )
	{
		self.player = player
		super.init( configuration:configuration, logger:logger )
		player.addPeriodicTimeObserver( forInterval:configuration.maxFrameDuration, queue:renderQueue )
		{
			[weak self] time in
			guard let self = self else
			{
				return
			}
			
			guard let output = self.player.displayOutput else
			{
				return
			}
			
			guard let pixelBuffer = output.copyPixelBuffer( forItemTime:time, itemTimeForDisplay:nil ) else
			{
				return
			}
			
			do
			{
				let sampleBuffer = try CMSampleBuffer.createSampleBufferFrom( pixelBuffer:pixelBuffer )
				self.enqueue( sampleBuffer )
			}
			catch
			{
				print( error.localizedDescription )
			}
		}
		
	
	}
}
