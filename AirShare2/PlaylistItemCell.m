//
//  PlaylistItemCell.m
//  AirShare2
//
//  Created by mata on 3/28/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PlaylistItemCell.h"

@implementation PlaylistItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier playlistItem:(PlaylistItem *)playlistItem voteValue:(int)voteValue
{
    self.playlistItem = playlistItem;
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.textLabel.text = playlistItem.name;
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.detailTextLabel.text = playlistItem.subtitle;
        self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
        
        // set status of buttons
        BOOL upvoteButtonEnabled = YES;
        BOOL downvoteButtonEnabled = YES;
        if(voteValue > 0) {
            upvoteButtonEnabled = NO;
        } else if(voteValue < 0) {
            downvoteButtonEnabled = NO;
        }
        
        _upvoteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _upvoteButton.frame = CGRectMake(270.0f, 5.0f, 30.0f, 30.0f);
        [_upvoteButton setTitle:@"+" forState:UIControlStateNormal];
        [_upvoteButton setEnabled:upvoteButtonEnabled];
        [self.contentView addSubview:_upvoteButton];
        
        self.upvoteLabel = [[UILabel alloc] init];
        _upvoteLabel.frame = CGRectMake(280.0f, 35.0f, 15.0f, 30.0f);
        _upvoteLabel.text = [NSString stringWithFormat:@"%d", [playlistItem getUpvoteCount]];
        [self.contentView addSubview:_upvoteLabel];
        
        _downvoteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _downvoteButton.frame = CGRectMake(5.0f, 5.0f, 30.0f, 30.0f);
        [_downvoteButton setTitle:@"-" forState:UIControlStateNormal];
        [_downvoteButton setEnabled:downvoteButtonEnabled];
        [self.contentView addSubview:_downvoteButton];
        
        self.downvoteLabel = [[UILabel alloc] init];
        _downvoteLabel.frame = CGRectMake(15.0f, 35.0f, 15.0f, 30.0f);
        _downvoteLabel.text = [NSString stringWithFormat:@"%d", [playlistItem getDownvoteCount]];
        [self.contentView addSubview:_downvoteLabel];
        
        _loadProgress = [[UIProgressView alloc] init];
        _loadProgress.frame = CGRectMake(55.0f, 50.0f, 200.0f, 15.0f);
        _loadProgress.progress = playlistItem.loadProgress;
        //NSLog(@"Load progress = %f", playlistItem.loadProgress);
        if(playlistItem.loadProgress != 1.0) {
            [self.contentView addSubview:_loadProgress];
        }
        
        [_upvoteButton addTarget:self
                          action:@selector(upvoteButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
        
        [_downvoteButton addTarget:self
                            action:@selector(downvoteButtonPressed:)
                  forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (IBAction)upvoteButtonPressed:(id)sender
{
    [_upvoteButton setEnabled:NO];
    
    [self.delegate voteForItem:_playlistItem withValue:1 upvote:YES];
    
    if(![_downvoteButton isEnabled]) {
        // user no longer wants it to be downvoted
        [self.delegate voteForItem:_playlistItem withValue:-1 upvote:NO];
        
        [_downvoteButton setEnabled:YES];
    }
    [self.delegate reloadTable];
}

- (IBAction)downvoteButtonPressed:(id)sender
{
    [_downvoteButton setEnabled:NO];
    
    [self.delegate voteForItem:_playlistItem withValue:1 upvote:NO];
    
    if(![_upvoteButton isEnabled]) {
        // user no longer wants it to be upvoted
        [self.delegate voteForItem:_playlistItem withValue:-1 upvote:YES];
        
        [_upvoteButton setEnabled:YES];
    }
    [self.delegate reloadTable];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    self.textLabel.frame = CGRectMake(0, self.textLabel.frame.origin.y - 5, self.frame.size.width, self.textLabel.frame.size.height - 5);
    self.detailTextLabel.frame = CGRectMake(0, self.detailTextLabel.frame.origin.y - 5, self.frame.size.width, self.detailTextLabel.frame.size.height - 5);
}
@end
