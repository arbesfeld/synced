//
//  MoviePickerViewController.h
//  AirShare2
//
//  Created by mata on 4/16/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "MovieItemCell.h"
#import "YouTubeTableViewController.h"

#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class MoviePickerViewController;

@protocol MoviePickerDelegate <NSObject>

- (void)addMovie:(MPMediaItem *)movieItem;
- (void)addYoutubeVideo:(YoutubeItem *)youtubeItem;

@end

@interface MoviePickerViewController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate, UIScrollViewDelegate, YouTubeDelegate> {
    NSArray *_labels;
    NSMutableArray *_searchData, *_allData;
    
    UISearchDisplayController *searchDisplayController;
    
    BOOL _shouldLoadImages;
}

@property (nonatomic, weak) id <MoviePickerDelegate> delegate;

@property (nonatomic, strong) UISearchBar *searchBar;
@end
