//
//  PacketMusic.m
//  AirShare2
//
//  Created by mata on 3/24/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PacketMusic.h"
#import "NSData+AirShareAdditions.h"

@implementation PacketMusic

+ (id)packetWithData:(NSData *)data
{
	size_t offset = PACKET_HEADER_SIZE;
	size_t count;
    
    NSString *songName = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
        
    NSString *artistName = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
    NSString *ID = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
	return [[self class] packetWithSongName:songName andArtistName:artistName andID:ID];
}

+ (id)packetWithSongName:(NSString *)songName andArtistName:(NSString *)artistName andID:(NSString *)ID
{
	return [[[self class] alloc] initWithSongName:songName andArtistName:artistName andID:(NSString *)ID];
}

- (id)initWithSongName:(NSString *)songName andArtistName:(NSString *)artistName andID:(NSString *)ID
{
	if ((self = [super initWithType:PacketTypeMusic]))
	{
		self.songName = songName;
        self.artistName = artistName;
        self.ID = ID;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendString:self.songName];
    [data rw_appendString:self.artistName];
    [data rw_appendString:self.ID];
}

@end