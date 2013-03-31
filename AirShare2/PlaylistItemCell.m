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
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.playlistItem = playlistItem;
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
        _upvoteButton.frame = CGRectMake(260.0f, 5.0f, 50.0f, 50.0f);
        [_upvoteButton setBackgroundImage:[UIImage imageNamed:@"upvote.png"] forState: UIControlStateNormal];
        [_upvoteButton setBackgroundImage:[UIImage imageNamed:@"upvote.png"] forState: UIControlStateHighlighted];
        [_upvoteButton setBackgroundImage:[UIImage imageNamed:@"upvote.png"] forState: UIControlStateSelected];
        [_upvoteButton setBackgroundImage:[UIImage imageNamed:@"upvote_selected.png"] forState: UIControlStateDisabled];
        _upvoteButton.showsTouchWhenHighlighted = YES;
        //[_upvoteButton setTitle:@"+" forState:UIControlStateNormal];
        [_upvoteButton setEnabled:upvoteButtonEnabled];
        
        self.upvoteLabel = [[UILabel alloc] init];
        _upvoteLabel.frame = CGRectMake(280.0f, 35.0f, 15.0f, 30.0f);
        _upvoteLabel.text = [NSString stringWithFormat:@"%d", [playlistItem getUpvoteCount]];
        _upvoteLabel.backgroundColor = [UIColor clearColor];
        
        _downvoteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _downvoteButton.frame = CGRectMake(-5.0f, 5.0f, 50.0f, 50.0f);
        [_downvoteButton setBackgroundImage:[UIImage imageNamed:@"downvote.png"] forState: UIControlStateNormal];
        [_downvoteButton setBackgroundImage:[UIImage imageNamed:@"downvote.png"] forState: UIControlStateHighlighted];
        [_downvoteButton setBackgroundImage:[UIImage imageNamed:@"downvote.png"] forState: UIControlStateSelected];
        [_downvoteButton setBackgroundImage:[UIImage imageNamed:@"downvote_selected.png"] forState: UIControlStateDisabled];
        _downvoteButton.showsTouchWhenHighlighted = YES;
        //[_downvoteButton setTitle:@"-" forState:UIControlStateNormal];
        [_downvoteButton setEnabled:downvoteButtonEnabled];
        
        self.downvoteLabel = [[UILabel alloc] init];
        _downvoteLabel.frame = CGRectMake(15.0f, 35.0f, 15.0f, 30.0f);
        _downvoteLabel.text = [NSString stringWithFormat:@"%d", [playlistItem getDownvoteCount]];
        _downvoteLabel.backgroundColor = [UIColor clearColor];
        
        _cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _cancelButton.frame = CGRectMake(260.0f, 5.0f, 50.0f, 50.0f);
        [_cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        
        _loadProgress = [[UIProgressView alloc] init];
        _loadProgress.frame = CGRectMake(55.0f, 50.0f, 200.0f, 15.0f);
        _loadProgress.progress = playlistItem.loadProgress;
        //NSLog(@"Load progress = %f", playlistItem.loadProgress);
        if(playlistItem.loadProgress != 1.0) {
            [self.contentView addSubview:_loadProgress];
            
            // Right now, cancel only cancels the upload operation.
            // We don't want to be canceling before the upload begins.
            if (playlistItem.loadProgress > 0.0 && !playlistItem.cancelled) {
                [self.contentView addSubview:_cancelButton];
            }
        } else {
            [self.contentView addSubview:_upvoteButton];
            [self.contentView addSubview:_upvoteLabel];
            [self.contentView addSubview:_downvoteButton];
            [self.contentView addSubview:_downvoteLabel];
        }
        
        [_upvoteButton addTarget:self
                          action:@selector(upvoteButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
        
        [_downvoteButton addTarget:self
                            action:@selector(downvoteButtonPressed:)
                  forControlEvents:UIControlEventTouchUpInside];
        
        [_cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
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

- (IBAction)cancelButtonPressed:(id)sender
{
    [self.playlistItem cancel];
    [_cancelButton removeFromSuperview];
    NSLog(@"Cancelled an upload.");
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
