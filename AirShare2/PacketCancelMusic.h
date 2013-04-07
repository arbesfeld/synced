//
//  PacketCancelMusic.h
//  AirShare2
//
//  Created by Alex Chen on 4/7/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "Packet.h"

@interface PacketCancelMusic : Packet

@property (nonatomic, strong) NSString *ID;

+ (id)packetWithID:(NSString *)ID;

@end