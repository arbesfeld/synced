//
//  PacketVote.m
//  AirShare2
//
//  Created by mata on 3/27/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PacketVote.h"
#import "NSData+AirShareAdditions.h"

@implementation PacketVote

+ (id)packetWithData:(NSData *)data
{
	size_t offset = PACKET_HEADER_SIZE;
	size_t count;
    
    NSString *ID = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
    int amount = [data rw_int8AtOffset:offset];
    offset += 1;
    
    int upvoteInt = [data rw_int8AtOffset:offset];
    offset += 1;
    
    BOOL upvote = upvoteInt == 1 ? YES : NO;
    
	return [[self class] packetWithSongID:ID andAmount:amount upvote:upvote];
}

+ (id)packetWithSongID:(NSString *)ID andAmount:(int)amount upvote:(BOOL)upvote
{
	return [[[self class] alloc] initWithSongID:ID andAmount:amount upvote:upvote];
}

- (id)initWithSongID:(NSString *)ID andAmount:(int)amount upvote:(BOOL)upvote{
	if ((self = [super initWithType:PacketTypeVote]))
	{
		self.ID = ID;
        _amount = amount;
        _upvote = upvote;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendString:self.ID];
    [data rw_appendInt8:_amount];
    if(_upvote) {
        [data rw_appendInt8:1];
    } else {
        [data rw_appendInt8:0];
    }
}

- (int)getAmount {
    return _amount;
}

- (BOOL)getUpvote {
    return _upvote;
}

@end