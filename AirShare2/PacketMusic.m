//
//  PacketMusic.m
//  AirShare2
//
//  Created by mata on 3/24/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PacketMusic.h"
#import "NSData+AirShareAdditions.h"
#import "MusicItem.h"

@implementation PacketMusic

+ (id)packetWithData:(NSData *)data
{
	size_t offset = PACKET_HEADER_SIZE;
	size_t count;
    
    NSString *songName = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
        
    NSString *artistName = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
    NSString *ID = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
    int fileSize = [data rw_int32AtOffset:offset];
    offset += 4;
    
    MusicItem *musicItem = [MusicItem musicItemWithName:songName andSubtitle:artistName andID:ID andFileSize:fileSize];
	return [[self class] packetWithMusicItem:musicItem];
}
 
+ (id)packetWithMusicItem:(MusicItem *)musicItem
{
	return [[[self class] alloc] initWithMusicItem:musicItem];
}

- (id)initWithMusicItem:(MusicItem *)musicItem
{
	if ((self = [super initWithType:PacketTypeMusic]))
	{
		self.musicItem = musicItem;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendString:self.musicItem.name];
    [data rw_appendString:self.musicItem.subtitle];
    [data rw_appendString:self.musicItem.ID];
    [data rw_appendInt32:self.musicItem.fileSize];
}

@end