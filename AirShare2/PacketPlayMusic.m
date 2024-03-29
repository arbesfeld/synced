//
//  PacketPlayMusic.m
//  AirShare2
//
//  Created by mata on 3/26/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//
//  Server to client -> play music at specific time

#import "PacketPlayMusic.h"
#import "NSData+AirShareAdditions.h"

@implementation PacketPlayMusic

+ (id)packetWithData:(NSData *)data
{
	size_t offset = PACKET_HEADER_SIZE;
	size_t count;
    
    int songTime = [data rw_int16AtOffset:offset];
    offset += 2;
    
    NSString *ID = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
    NSString *dateString = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
    // convert dateString to NSDate
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:DATE_FORMAT];
    NSDate *time = [dateFormatter dateFromString:dateString];
    
	return [[self class] packetWithSongID:ID andTime:time atSongTime:songTime];
}

+ (id)packetWithSongID:(NSString *)ID andTime:(NSDate *)time atSongTime:(int)songTime
{
	return [[[self class] alloc] initWithSongID:ID andTime:time atSongTime:songTime];
}

- (id)initWithSongID:(NSString *)ID andTime:(NSDate *)time atSongTime:(int)songTime
{
	if ((self = [super initWithType:PacketTypePlayMusic]))
	{
		self.ID = ID;
        self.time = time;
        self.songTime = songTime;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendInt16:self.songTime];
    
    [data rw_appendString:self.ID];
    
    // convert NSDate to dateString
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:DATE_FORMAT];
    NSString *dateString = [dateFormatter stringFromDate:self.time];
    [data rw_appendString:dateString];
    
}

@end
