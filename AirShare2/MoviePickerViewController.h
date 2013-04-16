//
//  MoviePickerViewController.h
//  AirShare2
//
//  Created by mata on 4/16/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "MovieItemCell.h"

#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>

@class MoviePickerViewController;

@protocol MoviePickerDelegate <NSObject>

- (void)addMovie:(MPMediaItem *)movieItem;

@end

@interface MoviePickerViewController : UITableViewController {
    NSArray *_movies, *_musicVideos, *_tvShows, *_podcasts, *_iTunesU;
    NSMutableArray *_movieCells, *_musicVideoCells, *_tvShowCells, *_podcastCells, *_iTunesUCells;
}

@property (nonatomic, weak) id <MoviePickerDelegate> delegate;

@end
