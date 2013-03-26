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

#pragma mark event handlers
-(id) initWithGame:(Game *)game {
    if (self = [super init]) {
        _game = game;
    }
    return self;
}
-(void)convertAndUpload:(MPMediaItem *)mediaItem {
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
    
    NSString *fileName = [NSString stringWithFormat:@"%@.m4a", [mediaItem valueForProperty:MPMediaItemPropertyTitle]];
    fileName = [fileName stringByReplacingOccurrencesOfString:@" " withString:@""];
	_exportPath = [documentsDirectoryPath stringByAppendingPathComponent:fileName];
    NSLog(@"Export path = %@", _exportPath);
    
	if ([[NSFileManager defaultManager] fileExistsAtPath:_exportPath]) {
        NSLog(@"removing item");
		[[NSFileManager defaultManager] removeItemAtPath:_exportPath error:nil];
	}
	NSURL *exportURL = [NSURL fileURLWithPath:_exportPath];
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

-(void)convertingComplete:(MPMediaItem *)mediaItem{
	//UInt64 convertedByteCount = [convertedByteCountNumber longValue];
	//sizeLabel.text = [NSString stringWithFormat: @"done. file size is %lld", convertedByteCount];
    // COMPLETED THE UPDATE
    NSURL *exportURL = [NSURL fileURLWithPath:_exportPath];
    NSLog(@"URL: %@", _exportPath);
    NSData *songData = [NSData dataWithContentsOfURL:exportURL];
    
    NSString *fileName = [NSString stringWithFormat:@"%@.m4a", [mediaItem valueForProperty:MPMediaItemPropertyTitle]];
    fileName = [fileName stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"Uploading to server: %@", fileName);
    
    NSURL *url = [NSURL URLWithString:@"http://protected-harbor-4741.herokuapp.com/"];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/airshare-upload.php" parameters:nil constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
        [formData appendPartWithFileData:songData name:@"musicfile" fileName:fileName mimeType:@"audio/x-m4a"];
    }];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
    }];
    [operation  setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success: %@", operation.responseString);
        
        [self sendMusicPacket:mediaItem];
    }
      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          NSLog(@"error: %@",  operation.responseString);
          
      }
     ];
    [httpClient enqueueHTTPRequestOperation:operation];
}

- (void)sendMusicPacket:(MPMediaItem *)mediaItem
{
    NSString *songName = [mediaItem valueForProperty:MPMediaItemPropertyTitle];
    NSString *artistName = [mediaItem valueForProperty:MPMediaItemPropertyArtist];
    NSURL *exportURL = [NSURL fileURLWithPath:_exportPath];
    MusicItem *musicItem = [MusicItem musicItemWithName:songName subtitle:artistName andURL:exportURL];
    [_game.playlist addObject:musicItem];
    [_game.delegate reloadTable];
    
    NSLog(@"Sending packet with songName %@ and artistName %@", songName, artistName);
    
    PacketMusic *packet = [PacketMusic packetWithSongName:songName andArtistName:artistName];
    
	GKSendDataMode dataMode = GKSendDataReliable;
	NSData *data = [packet data];
	NSError *error;
	if (![_game.session sendDataToAllPeers:data withDataMode:dataMode error:&error])
	{
		NSLog(@"Error sending data to clients: %@", error);
	}
    
}
@end
