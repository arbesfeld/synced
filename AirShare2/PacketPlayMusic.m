//
//  PacketTypePlayMusic.m
//  AirShare2
//
//  Created by mata on 3/26/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//
//  Server to client -> play music at specific time (at a certain point in the song)

#import "PacketPlayMusic.h"
#import "NSData+AirShareAdditions.h"

@implementation PacketPlayMusic

+ (id)packetWithData:(NSData *)data
{
	size_t offset = PACKET_HEADER_SIZE;
	size_t count;
    
    NSString *ID = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
    NSString *dateString = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
    // convert dateString to NSDate
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:DATE_FORMAT];
    NSDate *time = [dateFormatter dateFromString:dateString];
    
    int musicTime = [data rw_int32AtOffset:offset];
    offset += 4;
    
	return [[self class] packetWithSongID:ID andTime:time andMusicTime:musicTime];
}

+ (id)packetWithSongID:(NSString *)ID andTime:(NSDate *)time andMusicTime:(int)musicTime
{
	return [[[self class] alloc] initWithSongID:ID andTime:time andMusicTime:musicTime];
}

- (id)initWithSongID:(NSString *)ID andTime:(NSDate *)time andMusicTime:(int)musicTime
{
	if ((self = [super initWithType:PacketTypePlayMusic]))
	{
		self.ID = ID;
        self.time = time;
        self.musicTime = musicTime;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendString:self.ID];
    
    // convert NSDate to dateString
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:DATE_FORMAT];
    NSString *dateString = [dateFormatter stringFromDate:self.time];
    [data rw_appendString:dateString];
    
    [data rw_appendInt32:self.musicTime];
}

@end
