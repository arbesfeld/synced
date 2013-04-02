//
//  PacketMusic.h
//  AirShare2
//
//  Created by mata on 3/24/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "Packet.h"

@interface PacketMusicDownload : Packet

@property (nonatomic, strong) NSString *ID;

+ (id)packetWithID:(NSString *)ID;

@end
