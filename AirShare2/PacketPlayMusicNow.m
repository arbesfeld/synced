//
//  PacketPlayMusicNow.m
//  AirShare2
//
//  Created by mata on 3/26/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//
//  Server to client -> play music at specific time
#import "PacketPlayMusicNow.h"
#import "NSData+AirShareAdditions.h"

@implementation PacketPlayMusicNow

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
    NSDate *time = [[NSDate alloc] init];
    time = [dateFormatter dateFromString:dateString];
    
	return [[self class] packetWithSongID:ID andTime:time];
}

+ (id)packetWithSongID:(NSString *)ID andTime:(NSDate *)time
{
	return [[[self class] alloc] initWithSongID:ID andTime:time];
}

- (id)initWithSongID:(NSString *)ID andTime:(NSDate *)time
{
	if ((self = [super initWithType:PacketTypePlayMusicNow]))
	{
		self.ID = ID;
        self.time = time;
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
    NSLog(@"Date string = %@", dateString);
    [data rw_appendString:dateString];
}

@end
