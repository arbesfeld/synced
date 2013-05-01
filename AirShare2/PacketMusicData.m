//
//  PacketMusicData.m
//  AirShare2
//
//  Created by Alex Chen on 5/1/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PacketMusicData.h"
#import "NSData+AirShareAdditions.h"

@implementation PacketMusicData

+ (id)packetWithData:(NSData *)data
{
	size_t offset = PACKET_HEADER_SIZE;
	size_t count;
    
    NSString *ID = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
    int index = [data rw_int16AtOffset:offset];
    offset += 2;
    
    int length = [data rw_int16AtOffset:offset];
    offset += 2;
    
    NSString *dat = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
	return [[self class] packetWithSongID:ID andIndex:index andLength:length andData:dat];
}

+ (id)packetWithSongID:(NSString *)ID andIndex:(int)index andLength:(int)length andData:(NSString *)data;
{
	return [[[self class] alloc] initWithSongID:ID andIndex:index andLength:length andData:data];
}

- (id)initWithSongID:(NSString *)ID andIndex:(int)index andLength:(int)length andData:(NSString *)data;
{
	if ((self = [super initWithType:PacketTypeMusicData]))
	{
		self.ID = ID;
        self.index = index;
        self.length = length;
        self.data = data;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendString:self.ID];
    [data rw_appendInt16:self.index];
    [data rw_appendInt16:self.length];
    [data rw_appendString:self.data];    
}

@end
