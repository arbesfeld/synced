//
//  PacketMusic.h
//  AirShare2
//
//  Created by mata on 3/24/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "Packet.h"
#import "MusicItem.h"

@interface PacketMusic : Packet

@property (nonatomic, strong) MusicItem *musicItem;

+ (id)packetWithMusicItem:(MusicItem *)musicItem;

@end
