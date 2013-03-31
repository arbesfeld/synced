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
#import "PacketMusic.h"
#import "MusicItem.h"
#import "Game.h"

@implementation MusicUpload

- (void)convertAndUpload:(MusicItem *)musicItem withAssetURL:(NSURL *)assetURL andSessionID:(NSString *)sessionID completion:(void (^)())completionBlock{
	// set up an AVAssetReader to read from the iPod Library
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
    
    // export path is where it is saved locally
	NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@.m4a", musicItem.ID];
	NSString *exportPath = [documentsDirectoryPath stringByAppendingPathComponent:fileName];
    
	if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath]) {
		[[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
	}
	NSURL *exportURL = [NSURL fileURLWithPath:exportPath];
	AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:exportURL
														  fileType:AVFileTypeAppleM4A
															 error:&assetError];
	if (assetError) {
		NSLog (@"error: %@", assetError);
		return;
	}
	AudioChannelLayout channelLayout;
	memset(&channelLayout, 0, sizeof(AudioChannelLayout));
	channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                    [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                    [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                                    [NSNumber numberWithInt:128000], AVEncoderBitRateKey,
                                    [NSData dataWithBytes:&channelLayout    length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
                                    
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
                 
                 //NSNumber *convertedByteCountNumber = [NSNumber numberWithLong:convertedByteCount];
//                 [self performSelectorOnMainThread:@selector(updateSizeLabel:)
//                                        withObject:convertedByteCountNumber
//                                     waitUntilDone:NO];
             } else {
                 // done!
                 [assetWriterInput markAsFinished];
                 [assetWriter finishWritingWithCompletionHandler:^{
                     [assetReader cancelReading];
                     
                     NSDictionary *outputFileAttributes = [[NSFileManager defaultManager]
                                                           attributesOfItemAtPath:exportPath
                                                           error:nil];
                     NSLog (@"Converting done. File size is %lld", [outputFileAttributes fileSize]);
                     
                     // now upload to server
                     NSData *songData = [NSData dataWithContentsOfFile:exportPath];
                     NSString *fileName = [NSString stringWithFormat:@"%@.m4a", musicItem.ID];
                     
                     NSLog(@"Uploading to server: %@", fileName);
                     
                     NSURL *url = [NSURL URLWithString:BASE_URL];
                     AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
                     NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/airshare-upload.php" parameters:nil constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
                         [formData appendPartWithFileData:songData name:@"musicfile" fileName:fileName mimeType:@"audio/x-m4a"];
                         [formData appendPartWithFormData:[musicItem.ID dataUsingEncoding:NSUTF8StringEncoding]
                                                     name:@"id"];
                         [formData appendPartWithFormData:[sessionID dataUsingEncoding:NSUTF8StringEncoding]
                                                     name:@"sessionid"];
                     }];
                     AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
                     [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                         //NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
                         musicItem.loadProgress = (double)totalBytesWritten / totalBytesExpectedToWrite;
                     }];
                     [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                         NSLog(@"Upload Success: %@", operation.responseString);
                         musicItem.loadProgress = 1.0;
                         // now tell others that you have uploaded
                         completionBlock();
                     }
                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          NSLog(@"Upload Error: %@",  operation.responseString);
                          
                      }];
                     [httpClient enqueueHTTPRequestOperation:operation];
                     musicItem.uploadOperation = operation;
                 }];
                 
                 break;
             }
         }
	 }];
}

-(void)updateSizeLabel:(NSNumber*)convertedByteCountNumber {
	UInt64 convertedByteCount = [convertedByteCountNumber longValue];
	NSLog(@"%lld bytes converted", convertedByteCount);
}
@end
