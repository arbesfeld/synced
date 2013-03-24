//
//  PacketSignInResponse.m
//  AirShare2
//
//  Created by mata on 3/13/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PacketSignInResponse.h"
#import "NSData+AirShareAdditions.h"

@implementation PacketSignInResponse

@synthesize playerName = _playerName;

+ (id)packetWithPlayerName:(NSString *)playerName
{
	return [[[self class] alloc] initWithPlayerName:playerName];
}

+ (id)packetWithData:(NSData *)data
{
	size_t count;
	NSString *playerName = [data rw_stringAtOffset:PACKET_HEADER_SIZE bytesRead:&count];
    NSLog(@"creating packet with playername: %@", playerName);
	return [[self class] packetWithPlayerName:playerName];
}

- (id)initWithPlayerName:(NSString *)playerName
{
	if ((self = [super initWithType:PacketTypeSignInResponse]))
	{
		self.playerName = playerName;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
	[data rw_appendString:self.playerName];
}

@end
