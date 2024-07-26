//
//  CMSampleBuffer+ConvertPixelBuffer.swift
//  Hyssop
//
//  Created by Chris Hinkle on 9/26/23.
//

import Foundation
import CoreMedia
import CoreVideo
import os.log

/*
extension Logger
{
    func log( error:SampleBufferConversionProblem )
    {
        switch error
        {
        case .allocationFailed:
            logger.error( "SampleBufferConversionProblem allocation failed" )
            
        case .requiredParameterMissing:
            logger.error( "SampleBufferConversionProblem required parameter missing" )
        case .alreadyHasDataBuffer:
            logger.error( "SampleBufferConversionProblem already has data buffer" )
        case .bufferNotReady:
            logger.error( "SampleBufferConversionProblem bufferNotReady" )
        case .sampleIndexOutOfRange:
            logger.error( "SampleBufferConversionProblem sampleIndexOutOfRange" )
        case .bufferHasNoSampleSizes:
            logger.error( "SampleBufferConversionProblem bufferHasNoSampleSizes" )
        case .bufferHasNoSampleTimingInfo:
            logger.error( "SampleBufferConversionProblem bufferHasNoSampleTimingInfo" )
        case .arrayTooSmall:
            logger.error( "SampleBufferConversionProblem arrayTooSmall" )
        case .invalidEntryCount:
            logger.error( "SampleBufferConversionProblem invalidEntryCount" )
        case .cannotSubdivide:
            logger.error( "SampleBufferConversionProblem cannotSubdivide" )
        case .sampleTimingInfoInvalid:
            logger.error( "SampleBufferConversionProblem sampleTimingInfoInvalid" )
        case .invalidMediaTypeForOperation:
            logger.error( "SampleBufferConversionProblem invalidMediaTypeForOperation" )
        case .invalidSampleData:
            logger.error( "SampleBufferConversionProblem invalidSampleData" )
        case .invalidMediaFormat:
            logger.error( "SampleBufferConversionProblem invalidMediaFormat" )
        case .invalidated:
            logger.error( "SampleBufferConversionProblem invalidated" )
        case .dataFailed:
            logger.error( "SampleBufferConversionProblem dataFailed" )
        case .dataCanceled:
            logger.error( "SampleBufferConversionProblem dataCanceled" )
        case .unknown:
            logger.error( "SampleBufferConversionProblem unknown" )
        }
    }
}
 */

enum SampleBufferConversionProblem:OSStatus,Error
{
    case allocationFailed
    case requiredParameterMissing
    case alreadyHasDataBuffer
    case bufferNotReady
    case sampleIndexOutOfRange
    case bufferHasNoSampleSizes
    case bufferHasNoSampleTimingInfo
    case arrayTooSmall
    case invalidEntryCount
    case cannotSubdivide
    case sampleTimingInfoInvalid
    case invalidMediaTypeForOperation
    case invalidSampleData
    case invalidMediaFormat
    case invalidated
    case dataFailed
    case dataCanceled
    case unknown
    
    static func from( status:OSStatus ) -> SampleBufferConversionProblem?
    {
        switch status
        {
        case kCMSampleBufferError_AllocationFailed:
            return .allocationFailed
        case kCMSampleBufferError_RequiredParameterMissing:
            return .requiredParameterMissing
        case kCMSampleBufferError_AlreadyHasDataBuffer:
            return .alreadyHasDataBuffer
        case kCMSampleBufferError_BufferNotReady:
            return .bufferNotReady
        case kCMSampleBufferError_SampleIndexOutOfRange:
            return .sampleTimingInfoInvalid
        case kCMSampleBufferError_BufferHasNoSampleSizes:
            return .bufferHasNoSampleSizes
        case kCMSampleBufferError_BufferHasNoSampleTimingInfo:
            return .bufferHasNoSampleTimingInfo
        case kCMSampleBufferError_ArrayTooSmall:
            return .arrayTooSmall
        case kCMSampleBufferError_InvalidEntryCount:
            return .invalidEntryCount
        case kCMSampleBufferError_CannotSubdivide:
            return .cannotSubdivide
        case kCMSampleBufferError_SampleTimingInfoInvalid:
            return .sampleTimingInfoInvalid
        case kCMSampleBufferError_InvalidMediaTypeForOperation:
            return .invalidMediaTypeForOperation
        case kCMSampleBufferError_InvalidSampleData:
            return .invalidSampleData
        case kCMSampleBufferError_InvalidMediaFormat:
            return .invalidMediaFormat
        case kCMSampleBufferError_Invalidated:
            return .invalidated
        case kCMSampleBufferError_DataFailed:
            return .dataFailed
        case kCMSampleBufferError_DataCanceled:
            return .dataCanceled
        default:
            return .unknown
        
        }
    }
}

extension CMSampleBuffer
{
    public static func createSampleBufferFrom( pixelBuffer:CVPixelBuffer ) throws -> CMSampleBuffer
    {
        var sampleBuffer:CMSampleBuffer?
        
        let presentationTime = CMClockGetTime( CMClockGetHostTimeClock( ) )
        var timimgInfo = CMSampleTimingInfo( )
        timimgInfo.presentationTimeStamp = presentationTime
        var formatDescription:CMFormatDescription? = nil
        CMVideoFormatDescriptionCreateForImageBuffer( allocator:kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut:&formatDescription )
        
        
        let osStatus = CMSampleBufferCreateReadyWithImageBuffer(
          allocator: kCFAllocatorDefault,
          imageBuffer: pixelBuffer,
          formatDescription: formatDescription!,
          sampleTiming: &timimgInfo,
          sampleBufferOut: &sampleBuffer
        )
        
        guard let sampleBuffer = sampleBuffer else
        {
            guard let error = SampleBufferConversionProblem.from( status:osStatus ) else
            {
                throw SampleBufferConversionProblem.unknown
            }
            
            throw error
        }
        return sampleBuffer
    }
}
