//
//  PacketMusic.m
//  AirShare2
//
//  Created by mata on 3/24/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PacketMusicDownload.h"
#import "NSData+AirShareAdditions.h"

@implementation PacketMusicDownload

+ (id)packetWithData:(NSData *)data
{
	size_t offset = PACKET_HEADER_SIZE;
	size_t count;
    
    NSString *ID = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
	return [[self class] packetWithID:ID];
}
 
+ (id)packetWithID:(NSString *)ID
{
	return [[[self class] alloc] initWithID:ID];
}

- (id)initWithID:(NSString *)ID
{
	if ((self = [super initWithType:PacketTypeMusicDownload]))
	{
		self.ID = ID;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendString:self.ID];
}

@end