//
//  PacketPlaylistItem.m
//  AirShare2
//
//  Created by mata on 3/31/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PacketPlaylistItem.h"
#import "NSData+AirShareAdditions.h"
#import "Player.h"
#import "PlaylistItem.h"
#import "MediaItem.h"

@implementation PacketPlaylistItem

+ (id)packetWithData:(NSData *)data
{
	size_t offset = PACKET_HEADER_SIZE;
	size_t count;

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
    
    PlaylistItem *playlistItem;
    switch(playlistItemType) {
            // music item
        case PlaylistItemTypeSong:
        case PlaylistItemTypeMovie:
        {
            playlistItem = [MediaItem mediaItemWithName:name andSubtitle:subtitle andID:ID andDate:date andURL:nil uploadedByUser:NO andPlayListItemType:playlistItemType];
            [playlistItem setUpvoteCount:upvoteCount andDownvoteCount:downvoteCount];
            
            break;
        }
        case PlaylistItemTypeYoutube:
        {
            NSURL *url = [NSURL URLWithString:[data rw_stringAtOffset:offset bytesRead:&count]];
            offset += count;
            
            playlistItem = [MediaItem mediaItemWithName:name andSubtitle:subtitle andID:ID andDate:date andURL:url uploadedByUser:NO andPlayListItemType:playlistItemType];
            [playlistItem setUpvoteCount:upvoteCount andDownvoteCount:downvoteCount];
            break;
        }
        default:
            NSLog(@"Do not recognize playlistItemType!");
            break;
    }
    
	return [[self class] packetWithPlaylistItem:playlistItem];
}

+ (id)packetWithPlaylistItem:(PlaylistItem *)playlistItem
{
	return [[[self class] alloc] initWithPlaylistItem:playlistItem];
}

- (id)initWithPlaylistItem:(PlaylistItem *)playlistItem
{
	if ((self = [super initWithType:PacketTypePlaylistItem]))
	{
        self.playlistItem = playlistItem;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendString:self.playlistItem.name];
    [data rw_appendString:self.playlistItem.subtitle];
    [data rw_appendString:self.playlistItem.ID];
    
    // convert NSDate to dateString
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:DATE_FORMAT];
    NSString *dateString = [dateFormatter stringFromDate:self.playlistItem.date];
    [data rw_appendString:dateString];
    
    
    [data rw_appendInt8: [self.playlistItem getUpvoteCount]];
    [data rw_appendInt8: [self.playlistItem getDownvoteCount]];
    [data rw_appendInt8:  self.playlistItem.playlistItemType];
    
    if(self.playlistItem.playlistItemType == PlaylistItemTypeYoutube) {
        [data rw_appendString:[((MediaItem *)self.playlistItem).url absoluteString]];
    }
}

@end