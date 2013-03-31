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
@property (nonatomic, assign) int skipCount;

+ (id)packetWithPlayers:(NSMutableDictionary *)players andPlaylist:(NSMutableArray *)playlist andCurrentItem:(PlaylistItem *)currentPlaylistItem andSkipCount:(int)skipCount;

@end