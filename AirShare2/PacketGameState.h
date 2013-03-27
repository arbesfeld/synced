//
//  PacketGameList.h
//  AirShare2
//
//  Created by mata on 3/14/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "Packet.h"
#import "PlaylistItem.h"

@interface PacketGameState : Packet

@property (nonatomic, strong) NSMutableDictionary *players;
@property (nonatomic, strong) NSMutableArray *playlist;
@property (nonatomic, strong) PlaylistItem *currentPlaylistItem;

+ (id)packetWithPlayers:(NSMutableDictionary *)players andPlaylist:(NSMutableArray *)playlist andCurrentItem:(PlaylistItem *)currentPlaylistItem;

@end