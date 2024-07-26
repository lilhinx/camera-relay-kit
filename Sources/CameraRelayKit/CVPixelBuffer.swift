//
//  CVPixelBuffer.swift
//  Hyssop
//
//  Created by Chris Hinkle on 9/26/23.
//

import Foundation
import CoreVideo
import CoreGraphics

enum PixelBufferImageDrawProblem:Error
{
    case couldNotCreateContext
    case couldNotLockAddress
    case couldNotUnlockAddress
}

extension CVPixelBuffer
{
    fileprivate func context( width:Int, height:Int ) throws -> CGContext
    {
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB( )
        let result = CGContext( data: CVPixelBufferGetBaseAddress( self ), width:width, height:height, bitsPerComponent: 8, bytesPerRow:CVPixelBufferGetBytesPerRow( self ), space: rgbColorSpace, bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue )
        
        guard let result = result else
        {
            throw PixelBufferImageDrawProblem.couldNotCreateContext
        }
        return result
    }
    
    public func draw( image:CGImage ) throws
    {
        //draw image into pixel buffer
        guard CVPixelBufferLockBaseAddress( self, [] ) == 0 else
        {
            throw PixelBufferImageDrawProblem.couldNotLockAddress
        }
        
        let width = CVPixelBufferGetWidth( self )
        let height = CVPixelBufferGetHeight( self )
        let context = try context( width:width, height:height )
        context.interpolationQuality = .low
        context.draw( image, in:CGRect( x:0, y: 0, width: width, height: height ) )
        
        guard CVPixelBufferUnlockBaseAddress( self, [] ) == 0 else
        {
            throw PixelBufferImageDrawProblem.couldNotUnlockAddress
        }
    }
	
	public func drawBlank(  ) throws
	{
		//draw image into pixel buffer
		guard CVPixelBufferLockBaseAddress( self, [] ) == 0 else
		{
			throw PixelBufferImageDrawProblem.couldNotLockAddress
		}
		
		let width = CVPixelBufferGetWidth( self )
		let height = CVPixelBufferGetHeight( self )
		let context = try context( width:width, height:height )
		context.interpolationQuality = .low
		context.setFillColor( .black )
		context.fill( [ .init( x:0, y:0, width:width, height:height ) ] )
		
		guard CVPixelBufferUnlockBaseAddress( self, [] ) == 0 else
		{
			throw PixelBufferImageDrawProblem.couldNotUnlockAddress
		}
	}
	
	
	public static func blank( ) -> CVPixelBuffer
	{
		var pixelBuffer:CVPixelBuffer?
		
		
		guard CVPixelBufferCreate( kCFAllocatorDefault, 1920, 1080, kCVPixelFormatType_32BGRA, nil, &pixelBuffer ) == noErr else
		{
			fatalError( )
		}
		
		try! pixelBuffer!.drawBlank( )
		return pixelBuffer!
	}
}
