//
//  PacketPlayMusicNow.h
//  AirShare2
//
//  Created by mata on 3/26/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "Packet.h"

@interface PacketPlayMusicNow : Packet

@property (nonatomic, strong) NSString *ID;

+ (id)packetWithSongID:(NSString *)ID;

@end
