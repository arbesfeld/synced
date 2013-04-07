//
//  PacketSyncResponse.h
//  AirShare2
//
//  Created by mata on 4/6/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "Packet.h"

@interface PacketSyncResponse : Packet

@property (nonatomic, strong) NSDate *time;

+ (id)packetWithTime:(NSDate *)time;

@end
