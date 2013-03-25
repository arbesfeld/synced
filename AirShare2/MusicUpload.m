//
//  MusicUpload.m
//  AirShare2
//
//  Created by mata on 3/24/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "MusicUpload.h"
#import <AudioToolbox/AudioToolbox.h> // for the core audio constants
#import "AFNetworking.h"

#define EXPORT_NAME @"exported.caf"

@implementation MusicUpload

#pragma mark init/dealloc
- (void)dealloc {
    //[super dealloc];
}

#pragma mark event handlers

-(void) convertAndUpload:(MPMediaItem *)mediaItem {
	// set up an AVAssetReader to read from the iPod Library
	NSURL *assetURL = [mediaItem valueForProperty:MPMediaItemPropertyAssetURL];
	AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    
	NSError *assetError = nil;
	AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:songAsset
															   error:&assetError];
	if (assetError) {
		NSLog (@"error: %@", assetError);
		return;
	}
	
	AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderAudioMixOutput
											  assetReaderAudioMixOutputWithAudioTracks:songAsset.tracks
                                              audioSettings: nil];
	if (! [assetReader canAddOutput: assetReaderOutput]) {
		NSLog (@"can't add reader output... die!");
		return;
	}
	[assetReader addOutput: assetReaderOutput];
	
	NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
	_exportPath = [documentsDirectoryPath stringByAppendingPathComponent:EXPORT_NAME];
	if ([[NSFileManager defaultManager] fileExistsAtPath:_exportPath]) {
        NSLog(@"removing item");
		[[NSFileManager defaultManager] removeItemAtPath:_exportPath error:nil];
	}
	NSURL *exportURL = [NSURL fileURLWithPath:_exportPath];
	AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:exportURL
														  fileType:AVFileTypeCoreAudioFormat
															 error:&assetError];
	if (assetError) {
		NSLog (@"error: %@", assetError);
		return;
	}
	AudioChannelLayout channelLayout;
	memset(&channelLayout, 0, sizeof(AudioChannelLayout));
	channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
	NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
									[NSNumber numberWithFloat:44100.0], AVSampleRateKey,
									[NSNumber numberWithInt:2], AVNumberOfChannelsKey,
									[NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
									[NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
									[NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
									[NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
									[NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
									nil];
	AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
																			  outputSettings:outputSettings];
	if ([assetWriter canAddInput:assetWriterInput]) {
		[assetWriter addInput:assetWriterInput];
	} else {
		NSLog (@"can't add asset writer input... die!");
		return;
	}
	
	assetWriterInput.expectsMediaDataInRealTime = NO;
    
	[assetWriter startWriting];
	[assetReader startReading];
    
	AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
	CMTime startTime = CMTimeMake (0, soundTrack.naturalTimeScale);
	[assetWriter startSessionAtSourceTime: startTime];
	
	__block UInt64 convertedByteCount = 0;
	
	dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
	[assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue
											usingBlock: ^
	 {
        //NSLog (@"top of block");
		 while (assetWriterInput.readyForMoreMediaData) {
             CMSampleBufferRef nextBuffer = [assetReaderOutput copyNextSampleBuffer];
             if (nextBuffer) {
                 // append buffer
                 [assetWriterInput appendSampleBuffer: nextBuffer];
                 //				NSLog (@"appended a buffer (%d bytes)",
                 //					   CMSampleBufferGetTotalSampleSize (nextBuffer));
                 convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
                 // oops, no
                 // sizeLabel.text = [NSString stringWithFormat: @"%ld bytes converted", convertedByteCount];
                 
                 NSNumber *convertedByteCountNumber = [NSNumber numberWithLong:convertedByteCount];
                 [self performSelectorOnMainThread:@selector(updateSizeLabel:)
                                        withObject:convertedByteCountNumber
                                     waitUntilDone:NO];
             } else {
                 // done!
                 [assetWriterInput markAsFinished];
                 [assetWriter finishWriting];
                 [assetReader cancelReading];
                 NSDictionary *outputFileAttributes = [[NSFileManager defaultManager]
                                                       attributesOfItemAtPath:_exportPath
                                                       error:nil];
                 NSLog (@"done. file size is %lld", [outputFileAttributes fileSize]);
                 NSNumber *doneFileSize = [NSNumber numberWithLong:[outputFileAttributes fileSize]];
                 [self performSelectorOnMainThread:@selector(convertingComplete:)
                                       withObject:mediaItem
                                    waitUntilDone:NO];
                 break;
             }
         }
         
	 }];
	NSLog (@"bottom of convertTapped:");
}

-(void)updateSizeLabel:(NSNumber*)convertedByteCountNumber {
	UInt64 convertedByteCount = [convertedByteCountNumber longValue];
	NSLog(@"%lld bytes converted", convertedByteCount);
}

-(void)convertingComplete:(MPMediaItem *)mediaItem {
	//UInt64 convertedByteCount = [convertedByteCountNumber longValue];
	//sizeLabel.text = [NSString stringWithFormat: @"done. file size is %lld", convertedByteCount];
    // COMPLETED THE UPDATE
    NSURL *exportURL = [NSURL fileURLWithPath:_exportPath];
    NSLog(@"URL: %@", _exportPath);
    NSData *songData = [NSData dataWithContentsOfURL:exportURL];
    
    NSString *fileName = [NSString stringWithFormat:@"%@.caf", [mediaItem valueForProperty:MPMediaItemPropertyTitle]];
    NSLog(@"Uploading to server: %@", fileName);
    
    NSURL *url = [NSURL URLWithString:@"http://www.axchen.com/"];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/airshare-server.php" parameters:nil constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
        [formData appendPartWithFileData:songData name:@"musicfile" fileName:fileName mimeType:@"audio/x-caf"];
    }];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
    }];
    [operation  setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success: %@", operation.responseString);
    }
      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          NSLog(@"error: %@",  operation.responseString);
          
      }
     ];
    [httpClient enqueueHTTPRequestOperation:operation];
}

@end
