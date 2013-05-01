//
//  PacketMusicData.h
//  AirShare2
//
//  Created by Alex Chen on 5/1/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "Packet.h"

@interface PacketMusicData : Packet

@property (nonatomic, assign) NSString *ID;
@property (nonatomic, assign) int index;
@property (nonatomic, assign) int length;
@property (nonatomic, strong) NSString *data;

+ (id)packetWithSongID:(NSString *)ID andIndex:(int)index andLength:(int)length andData:(NSString *)data;

@end
