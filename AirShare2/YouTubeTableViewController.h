//
//  YouTubeTableViewController.h
//  AirShare2
//
//  Created by mata on 4/21/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBJson.h"
#import "MovieItemCell.h"
#import "MediaItem.h"

@class YouTubeTableViewController;

@protocol YouTubeDelegate <NSObject>

- (void)addYoutubeVideo:(MediaItem *)youtubeItem;

@end

@interface YouTubeTableViewController : UITableViewController <UISearchBarDelegate, NSURLConnectionDelegate> {
	NSMutableArray			*_videoTitle;
	NSMutableArray			*_videoURL;
	NSMutableArray			*_videoDescription;
	NSMutableArray			*_videoThumbnailImageURL;
	NSMutableArray			*_videoDuration;
}

@property (nonatomic, weak) id <YouTubeDelegate> delegate;
@property (nonatomic, strong) UISearchBar *searchBar;

@end
