//
//  PacketMusicResponse.m
//  AirShare2
//
//  Created by mata on 3/26/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PacketMusicResponse.h"
#import "NSData+AirShareAdditions.h"

@implementation PacketMusicResponse

+ (id)packetWithData:(NSData *)data
{
	size_t offset = PACKET_HEADER_SIZE;
	size_t count;
    
    NSString *ID = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
	return [[self class] packetWithSongID:ID];
}

+ (id)packetWithSongID:(NSString *)ID
{
	return [[[self class] alloc] initWithSongID:ID];
}

- (id)initWithSongID:(NSString *)ID{
	if ((self = [super initWithType:PacketTypeMusicResponse]))
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
