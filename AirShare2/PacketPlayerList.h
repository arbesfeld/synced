//
//  PacketPlayerList.h
//  AirShare2
//
//  Created by mata on 3/14/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "Packet.h"

@interface PacketPlayerList : Packet

@property (nonatomic, strong) NSMutableDictionary *players;

+ (id)packetWithPlayers:(NSMutableDictionary *)players;

@end