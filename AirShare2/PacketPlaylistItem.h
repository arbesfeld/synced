//
//  PacketPlaylistItem.h
//  AirShare2
//
//  Created by mata on 3/31/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "Packet.h"
#import "PlaylistItem.h"

@interface PacketPlaylistItem : Packet

@property (nonatomic, strong) PlaylistItem *playlistItem;

+ (id)packetWithPlaylistItem:(PlaylistItem *)playlistItem;

@end