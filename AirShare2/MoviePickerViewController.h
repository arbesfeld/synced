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

@interface MoviePickerViewController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate, UIScrollViewDelegate> {
    NSArray *_labels;
    NSMutableArray *_searchData, *_allData;
    
    UISearchDisplayController *searchDisplayController;
    
    BOOL _shouldLoadImages;
}

@property (nonatomic, weak) id <MoviePickerDelegate> delegate;

@property (nonatomic, strong) UISearchBar *searchBar;
@end
