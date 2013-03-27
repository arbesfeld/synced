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
    
    NSString *songName = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
	return [[self class] packetWithSongName:songName];
}

+ (id)packetWithSongName:(NSString *)songName
{
	return [[[self class] alloc] initWithSongName:songName];
}

- (id)initWithSongName:(NSString *)songName{
	if ((self = [super initWithType:PacketTypeMusicResponse]))
	{
		self.songName = songName;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendString:self.songName];
}

@end
