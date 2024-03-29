//
//  PlaylistItemCell.h
//  AirShare2
//
//  Created by mata on 3/28/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "PlaylistItem.h"
#import "UIButton+Extensions.h"

@class PlaylistItemCell;

@protocol PlaylistItemDelegate <NSObject>

- (void)voteForItem:(PlaylistItem *)playlistItem withValue:(int)value upvote:(BOOL)upvote;
- (void)cancelMusicAndUpdateAll:(PlaylistItem *)playlistItem;
- (void)reloadTable;

@end

@interface PlaylistItemCell : UITableViewCell {
    NSTimer *_updateLoadProgress;
    BOOL _upvotePressed;
}

@property (nonatomic, weak) id <PlaylistItemDelegate> delegate;

@property (nonatomic, weak) UIButton *upvoteButton, *downvoteButton, *cancelButton;
@property (nonatomic, strong) UILabel *upvoteLabel, *downvoteLabel, *positionLabel;
@property (nonatomic, strong) UIImageView *waitingView, *iconView;
@property (nonatomic, strong) UIView *loadProgress;
@property (nonatomic, strong) PlaylistItem *playlistItem;
@property (nonatomic, assign) int position;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier playlistItem:(PlaylistItem *)playlistItem voted:(BOOL)voted position:(int)position;
@end
