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
#import "MusicItem.h"

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
                MusicItem *musicItem = [MusicItem musicItemWithName:name andSubtitle:subtitle andID:ID];
                [musicItem setUpvoteCount:upvoteCount andDownvoteCount:downvoteCount];
                [playlist addObject:musicItem];
                
                break;
            }
            default:
                NSLog(@"Do not recognize playlistItemType!");
                break;
        }
	}
	return [[self class] packetWithPlayers:players andPlaylist:playlist];
}

+ (id)packetWithPlayers:(NSMutableDictionary *)players andPlaylist:(NSMutableArray *)playlist
{
	return [[[self class] alloc] initWithPlayers:players andPlaylist:playlist];
}

- (id)initWithPlayers:(NSMutableDictionary *)players andPlaylist:(NSMutableArray *)playlist
{
	if ((self = [super initWithType:PacketTypeGameState]))
	{
		self.players = players;
        self.playlist = playlist;
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
         [data rw_appendInt8: [playlistItem getUpvoteCount]];
         [data rw_appendInt8: [playlistItem getDownvoteCount]];
        
         if(playlistItem.playlistItemType == PlaylistItemTypeSong) {
             [data rw_appendInt8:PlaylistItemTypeSong];
         }
     }
}

@end