//
//  PacketPlayMusic.h
//  AirShare2
//
//  Created by mata on 3/26/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "Packet.h"

@interface PacketPlayMusic : Packet

@property (nonatomic, strong) NSString *ID;
@property (nonatomic, strong) NSDate *time;
@property (nonatomic, assign) int songTime;

+ (id)packetWithSongID:(NSString *)ID andTime:(NSDate *)time atSongTime:(int)songTime;

@end
