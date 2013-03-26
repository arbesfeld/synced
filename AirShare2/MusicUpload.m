//
//  MusicUpload.m
//  AirShare2
//
//  Created by mata on 3/24/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "MusicUpload.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h> // for the core audio constants
#import "all.h"
#import <CoreMedia/CoreMedia.h>

#import "AFNetworking.h"
#import "PacketMusic.h"
#import "MusicItem.h"
#import "Game.h"

@class AVURLAsset, AVAssetReader, AVAssetReaderTrackOutput;

//typedef void *CMSampleBufferRef;
//typedef void *CMBlockBufferRef;

@implementation MusicUpload 

// FLAC encoder output callback
FLAC__StreamEncoderWriteStatus FLAC_writeCallback(const FLAC__StreamEncoder *encoder, const FLAC__byte *buffer, size_t bytes, unsigned samples, unsigned current_frame, void *ctx)
{
	NSMutableData *flacData = (__bridge NSMutableData *)(ctx);
	[flacData appendBytes:buffer length:bytes];
	return FLAC__STREAM_ENCODER_WRITE_STATUS_OK;
}

#pragma mark event handlers
-(id) initWithGame:(Game *)game {
    if (self = [super init]) {
        _game = game;
    }
    return self;
}
-(void)convertAndUpload:(MPMediaItem *)mediaItem {
    NSLog(@"Converting and uploading...");
    // Get raw PCM data from the track
    NSURL *assetURL = [mediaItem valueForProperty:MPMediaItemPropertyAssetURL];
    NSMutableData *data = [[NSMutableData alloc] init];
    
    const uint32_t sampleRate = 16000;
    const uint16_t bitDepth = 16;
    const uint16_t channels = 2;
    
    NSDictionary *opts = [NSDictionary dictionary];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:assetURL options:opts];
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:NULL];
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                              [NSNumber numberWithFloat:(float)sampleRate], AVSampleRateKey,
                              [NSNumber numberWithInt:bitDepth], AVLinearPCMBitDepthKey,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey, nil];
    
    AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc] initWithTrack:[[asset tracks] objectAtIndex:0] outputSettings:settings];
    [reader addOutput:output];
    [reader startReading];
    
    // read the samples from the asset and append them subsequently
    while ([reader status] != AVAssetReaderStatusCompleted) {
        CMSampleBufferRef buffer = [output copyNextSampleBuffer];
        if (buffer == NULL) continue;
        
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(buffer);
        size_t size = CMBlockBufferGetDataLength(blockBuffer);
        uint8_t *outBytes = malloc(size);
        CMBlockBufferCopyDataBytes(blockBuffer, 0, size, outBytes);
        CMSampleBufferInvalidate(buffer);
        CFRelease(buffer);
        [data appendBytes:outBytes length:size];
        free(outBytes);
    }
    
    // Encode the PCM data to FLAC
    uint32_t totalSamples = [data length] / (channels * bitDepth / 8);
    NSMutableData *flacData = [[NSMutableData alloc] init];
    
    // Create a FLAC encoder
    FLAC__StreamEncoder *encoder = FLAC__stream_encoder_new();
    if (encoder == NULL)
    {
        // handle error
    }
    
    // Set up the encoder
    FLAC__stream_encoder_set_verify(encoder, true);
    FLAC__stream_encoder_set_compression_level(encoder, 8);
    FLAC__stream_encoder_set_channels(encoder, channels);
    FLAC__stream_encoder_set_bits_per_sample(encoder, bitDepth);
    FLAC__stream_encoder_set_sample_rate(encoder, sampleRate);
    FLAC__stream_encoder_set_total_samples_estimate(encoder, totalSamples);
    
    // Initialize the encoder
    FLAC__stream_encoder_init_stream(encoder, FLAC_writeCallback, NULL, NULL, NULL, (__bridge void *)(flacData));
    
    // Start encoding
    size_t left = totalSamples;
    const size_t buffsize = 1 << 16;
    FLAC__byte *buffer;
    static FLAC__int32 pcm[1 << 17];
    size_t need;
    size_t i;
    while (left > 0) {
        need = left > buffsize ? buffsize : left;
        
        buffer = (FLAC__byte *)[data bytes] + (totalSamples - left) * channels * bitDepth / 8;
        for (i = 0; i < need * channels; i++) {
            if (bitDepth == 16) {
                // 16 bps, signed little endian
                pcm[i] = *(int16_t *)(buffer + i * 2);
            } else {
                // 8 bps, unsigned
                pcm[i] = *(uint8_t *)(buffer + i);
            }
        }
        
        FLAC__bool succ = FLAC__stream_encoder_process_interleaved(encoder, pcm, need);
        if (succ == 0) {
            FLAC__stream_encoder_delete(encoder);
            // handle error
            return;
        }
        
        left -= need;
    }
    
    // Clean up
    FLAC__stream_encoder_finish(encoder);
    FLAC__stream_encoder_delete(encoder);
    
    NSString *fileName = [NSString stringWithFormat:@"%@.flac", [mediaItem valueForProperty:MPMediaItemPropertyTitle]];
    fileName = [fileName stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"Filename = %@", fileName);
    
	NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
	_exportPath = [documentsDirectoryPath stringByAppendingPathComponent:fileName];
	if ([[NSFileManager defaultManager] fileExistsAtPath:_exportPath]) {
        NSLog(@"removing item");
		[[NSFileManager defaultManager] removeItemAtPath:_exportPath error:nil];
	}
	[flacData writeToFile:_exportPath atomically:NO];
    [self convertingComplete:mediaItem];
    
}

-(void)convertingComplete:(MPMediaItem *)mediaItem{
	//UInt64 convertedByteCount = [convertedByteCountNumber longValue];
	//sizeLabel.text = [NSString stringWithFormat: @"done. file size is %lld", convertedByteCount];
    // COMPLETED THE UPDATE
    NSURL *exportURL = [NSURL fileURLWithPath:_exportPath];
    NSLog(@"URL: %@", _exportPath);
    NSData *songData = [NSData dataWithContentsOfURL:exportURL];
    
    NSString *fileName = [NSString stringWithFormat:@"%@.flac", [mediaItem valueForProperty:MPMediaItemPropertyTitle]];
    fileName = [fileName stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"Uploading to server: %@", fileName);
    
    NSURL *url = [NSURL URLWithString:@"http://protected-harbor-4741.herokuapp.com/"];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/airshare-upload.php" parameters:nil constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
        [formData appendPartWithFileData:songData name:@"musicfile" fileName:fileName mimeType:@"audio/x-flac"];
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
