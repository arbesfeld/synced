//
//  PacketVote.h
//  AirShare2
//
//  Created by mata on 3/27/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "Packet.h"

@interface PacketVote : Packet {
    int _amount;
    BOOL _upvote;
}

@property (nonatomic, strong) NSString *ID;

+ (id)packetWithSongID:(NSString *)ID andAmount:(int)amount upvote:(BOOL)upvote;

- (int)getAmount;
- (BOOL)getUpvote;
@end