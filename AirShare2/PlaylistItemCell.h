//
//  PlaylistItemCell.h
//  AirShare2
//
//  Created by mata on 3/28/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlaylistItem.h"

@class PlaylistItemCell;

@protocol PlaylistItemDelegate <NSObject>

- (void)voteForItem:(PlaylistItem *)playlistItem withValue:(int)value upvote:(BOOL)upvote;
- (void)cancelMusicAndUpdateAll:(PlaylistItem *)playlistItem;
- (void)reloadTable;

@end

@interface PlaylistItemCell : UITableViewCell

@property (nonatomic, weak) id <PlaylistItemDelegate> delegate;

@property (nonatomic, weak) UIButton *upvoteButton;
@property (nonatomic, weak) UIButton *downvoteButton;
@property (nonatomic, strong) UILabel *upvoteLabel;
@property (nonatomic, strong) UILabel *downvoteLabel;
@property (nonatomic, weak) UIButton *cancelButton;
@property (nonatomic, strong) UIImageView *waitingView;
@property (nonatomic, strong) UIProgressView *loadProgress;
@property (nonatomic, strong) PlaylistItem *playlistItem;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier playlistItem:(PlaylistItem *)playlistItem voteValue:(int)voteValue;
@end
