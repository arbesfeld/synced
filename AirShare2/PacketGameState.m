//
//  PacketGameState.m
//  AirShare2
//
//  Created by mata on 3/14/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PacketGameState.h"
#import "NSData+AirShareAdditions.h"
#import "Player.h"
#import "PlaylistItem.h"
#import "MediaItem.h"

@implementation PacketGameState

@synthesize players = _players;

+ (id)packetWithData:(NSData *)data
{
	NSMutableDictionary *players = [NSMutableDictionary dictionaryWithCapacity:4];
	NSMutableArray *playlist = [[NSMutableArray alloc] initWithCapacity:10];
    
	size_t offset = PACKET_HEADER_SIZE;
	size_t count;
    
	int numberOfPlayers = [data rw_int8AtOffset:offset];
	offset += 1;
    
	for (int t = 0; t < numberOfPlayers; ++t)
	{
		NSString *peerID = [data rw_stringAtOffset:offset bytesRead:&count];
		offset += count;
        
		NSString *name = [data rw_stringAtOffset:offset bytesRead:&count];
		offset += count;
        
		Player *player = [[Player alloc] init];
		player.peerID = peerID;
		player.name = name;
		[players setObject:player forKey:player.peerID];
	}
    
    int numberOfPlaylistItems = [data rw_int8AtOffset:offset];
	offset += 1;
    
	for (int t = 0; t < numberOfPlaylistItems; ++t)
	{
		NSString *name = [data rw_stringAtOffset:offset bytesRead:&count];
		offset += count;
        
		NSString *subtitle = [data rw_stringAtOffset:offset bytesRead:&count];
		offset += count;
        
		NSString *ID = [data rw_stringAtOffset:offset bytesRead:&count];
		offset += count;
        
        
        NSString *dateString = [data rw_stringAtOffset:offset bytesRead:&count];
        offset += count;
        
        // convert dateString to NSDate
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:DATE_FORMAT];
        NSDate *date = [[NSDate alloc] init];
        date = [dateFormatter dateFromString:dateString];
        
        int upvoteCount = [data rw_int8AtOffset:offset];
        offset += 1;
        
        int downvoteCount = [data rw_int8AtOffset:offset];
        offset += 1;
        
        int playlistItemType = [data rw_int8AtOffset:offset];
        offset += 1;
        
        
        switch(playlistItemType) {
            // music item
            case PlaylistItemTypeSong:
            {
                MediaItem *mediaItem = [MediaItem mediaItemWithName:name andSubtitle:subtitle andID:ID andDate:date];
                [mediaItem setUpvoteCount:upvoteCount andDownvoteCount:downvoteCount];
                [playlist addObject:mediaItem];
                
                break;
            }
            default:
                NSLog(@"Do not recognize playlistItemType!");
                break;
        }
	}
    NSString *currentName = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
    NSString *currentSubtitle = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
    NSString *currentID = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
    int currentPlaylistItemType = [data rw_int8AtOffset:offset];
    offset += 1;
    
    PlaylistItem *currentPlaylistItem = [[PlaylistItem alloc] initPlaylistItemWithName:currentName andSubtitle:currentSubtitle andID:currentID andDate:nil andPlaylistItemType:currentPlaylistItemType];
    
    int skipSongCount = [data rw_int8AtOffset:offset];
    offset += 1;
    
	return [[self class] packetWithPlayers:players andPlaylist:playlist andCurrentItem:currentPlaylistItem andSkipCount:skipSongCount];
}

+ (id)packetWithPlayers:(NSMutableDictionary *)players andPlaylist:(NSMutableArray *)playlist andCurrentItem:(PlaylistItem *)currentPlaylistItem andSkipCount:(int)skipCount
{
	return [[[self class] alloc] initWithPlayers:players andPlaylist:playlist andCurrentItem:currentPlaylistItem andSkipCount:skipCount];
}

- (id)initWithPlayers:(NSMutableDictionary *)players andPlaylist:(NSMutableArray *)playlist andCurrentItem:(PlaylistItem *)currentPlaylistItem andSkipCount:(int)skipCount
{
	if ((self = [super initWithType:PacketTypeGameState]))
	{
		self.players = players;
        self.playlist = playlist;
        self.currentPlaylistItem = currentPlaylistItem;
        self.skipCount = skipCount;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
	[data rw_appendInt8:[self.players count]];
    
	[self.players enumerateKeysAndObjectsUsingBlock:^(id key, Player *player, BOOL *stop)
     {
         [data rw_appendString:player.peerID];
         [data rw_appendString:player.name];
     }];
    
    [data rw_appendInt8:[self.playlist count]];
    
	for(PlaylistItem *playlistItem in self.playlist) {
        [data rw_appendString:playlistItem.name];
        [data rw_appendString:playlistItem.subtitle];
        [data rw_appendString:playlistItem.ID];
        
        // convert NSDate to dateString
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:DATE_FORMAT];
        NSString *dateString = [dateFormatter stringFromDate:playlistItem.date];
        [data rw_appendString:dateString];
        
        [data rw_appendInt8: [playlistItem getUpvoteCount]];
        [data rw_appendInt8: [playlistItem getDownvoteCount]];
        [data rw_appendInt8:  playlistItem.playlistItemType];
     }
    
    [data rw_appendString:self.currentPlaylistItem.name];
    [data rw_appendString:self.currentPlaylistItem.subtitle];
    [data rw_appendString:self.currentPlaylistItem.ID];
    [data rw_appendInt8:  self.currentPlaylistItem.playlistItemType];
    
    [data rw_appendInt8:  self.skipCount];
}

@end