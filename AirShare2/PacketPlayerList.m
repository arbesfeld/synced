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