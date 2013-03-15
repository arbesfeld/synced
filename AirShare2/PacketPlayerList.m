//
//  PacketPlayerList.m
//  AirShare2
//
//  Created by mata on 3/14/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PacketPlayerList.h"
#import "NSData+AirShareAdditions.h"
#import "Player.h"

@implementation PacketPlayerList

@synthesize players = _players;

+ (id)packetWithData:(NSData *)data
{
	NSMutableDictionary *players = [NSMutableDictionary dictionaryWithCapacity:4];
    
	size_t offset = PACKET_HEADER_SIZE;
	size_t count;
    
	int numberOfPlayers = [data rw_int8AtOffset:offset];
	offset += 1;
    
	for (int t = 0; t < numberOfPlayers; ++t)
	{
		NSString *peerID = [data rw_stringAtOffset:offset bytesRead:&count];
		offset += count;
        
		NSString *name = [data rw_stringAtOffset:offset bytesRead:&count];
		offset += count;
        
		Player *player = [[Player alloc] init];
		player.peerID = peerID;
		player.name = name;
		[players setObject:player forKey:player.peerID];
	}
    
	return [[self class] packetWithPlayers:players];
}

+ (id)packetWithPlayers:(NSMutableDictionary *)players
{
	return [[[self class] alloc] initWithPlayers:players];
}

- (id)initWithPlayers:(NSMutableDictionary *)players
{
	if ((self = [super initWithType:PacketTypeServerReady]))
	{
		self.players = players;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
	[data rw_appendInt8:[self.players count]];
    
	[self.players enumerateKeysAndObjectsUsingBlock:^(id key, Player *player, BOOL *stop)
     {
         [data rw_appendString:player.peerID];
         [data rw_appendString:player.name];
     }];
}

@end