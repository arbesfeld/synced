//
//  PacketSyncResponse.m
//  AirShare2
//
//  Created by mata on 4/6/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PacketSyncResponse.h"
#import "NSData+AirShareAdditions.h"

@implementation PacketSyncResponse

+ (id)packetWithData:(NSData *)data
{
	size_t offset = PACKET_HEADER_SIZE;
	size_t count;
    
    NSString *dateString = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
    // convert dateString to NSDate
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:DATE_FORMAT];
    NSDate *time = [dateFormatter dateFromString:dateString];

	return [[self class] packetWithTime:time];
}

+ (id)packetWithTime:(NSDate *)time
{
	return [[[self class] alloc] initWithTime:time];
}

- (id)initWithTime:(NSDate *)time
{
	if ((self = [super initWithType:PacketTypeSyncResponse]))
	{
        self.time = time;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    // convert NSDate to dateString
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:DATE_FORMAT];
    NSString *dateString = [dateFormatter stringFromDate:self.time];
    [data rw_appendString:dateString];
}

@end
