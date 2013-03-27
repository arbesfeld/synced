//
//  PacketMusicResponse.h
//  AirShare2
//
//  Created by mata on 3/26/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "Packet.h"

@interface PacketMusicResponse : Packet

@property (nonatomic, strong) NSString *songName;

+ (id)packetWithSongName:(NSString *)songName;

@end