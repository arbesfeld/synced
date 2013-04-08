//
//  PlaylistItemCell.m
//  AirShare2
//
//  Created by mata on 3/28/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PlaylistItemCell.h"
#import "UIImage+animatedGIF.h"

@implementation PlaylistItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier playlistItem:(PlaylistItem *)playlistItem voteValue:(int)voteValue
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.playlistItem = playlistItem;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.textLabel.text = playlistItem.name;
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.detailTextLabel.text = playlistItem.subtitle;
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
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
        _upvoteButton.frame = CGRectMake(270.0f, 0.0f, 50.0f, 50.0f);
        [_upvoteButton setBackgroundImage:[UIImage imageNamed:@"upvote.png"] forState: UIControlStateNormal];
        [_upvoteButton setBackgroundImage:[UIImage imageNamed:@"upvote.png"] forState: UIControlStateHighlighted];
        [_upvoteButton setBackgroundImage:[UIImage imageNamed:@"upvote.png"] forState: UIControlStateSelected];
        [_upvoteButton setBackgroundImage:[UIImage imageNamed:@"upvote_selected.png"] forState: UIControlStateDisabled];
        _upvoteButton.showsTouchWhenHighlighted = YES;
        //[_upvoteButton setTitle:@"+" forState:UIControlStateNormal];
        [_upvoteButton setEnabled:upvoteButtonEnabled];
        
        self.upvoteLabel = [[UILabel alloc] init];
        _upvoteLabel.frame = CGRectMake(290.0f, 30.0f, 15.0f, 30.0f);
        _upvoteLabel.text = [NSString stringWithFormat:@"%d", [playlistItem getUpvoteCount]];
        _upvoteLabel.backgroundColor = [UIColor clearColor];
        
        _downvoteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _downvoteButton.frame = CGRectMake(0.0f, 0.0f, 50.0f, 50.0f);
        [_downvoteButton setBackgroundImage:[UIImage imageNamed:@"downvote.png"] forState: UIControlStateNormal];
        [_downvoteButton setBackgroundImage:[UIImage imageNamed:@"downvote.png"] forState: UIControlStateHighlighted];
        [_downvoteButton setBackgroundImage:[UIImage imageNamed:@"downvote.png"] forState: UIControlStateSelected];
        [_downvoteButton setBackgroundImage:[UIImage imageNamed:@"downvote_selected.png"] forState: UIControlStateDisabled];
        _downvoteButton.showsTouchWhenHighlighted = YES;
        //[_downvoteButton setTitle:@"-" forState:UIControlStateNormal];
        [_downvoteButton setEnabled:downvoteButtonEnabled];
        
        self.downvoteLabel = [[UILabel alloc] init];
        _downvoteLabel.frame = CGRectMake(20.0f, 30.0f, 15.0f, 30.0f);
        _downvoteLabel.text = [NSString stringWithFormat:@"%d", [playlistItem getDownvoteCount]];
        _downvoteLabel.backgroundColor = [UIColor clearColor];

        NSURL *url = [[NSBundle mainBundle] URLForResource:@"loading" withExtension:@"gif"];
        _waitingView = [[UIImageView alloc] initWithFrame:CGRectMake(20.0f, 20.0f, 20.0f, 20.0f)];
        _waitingView.image = [UIImage animatedImageWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
        
        _cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _cancelButton.frame = CGRectMake(255.0f, 0.0f, 70.0f, 70.0f);
        [_cancelButton setBackgroundImage:[UIImage imageNamed:@"cancel.png"] forState: UIControlStateNormal];
        [_cancelButton setBackgroundImage:[UIImage imageNamed:@"cancel.png"] forState: UIControlStateHighlighted];
        [_cancelButton setBackgroundImage:[UIImage imageNamed:@"cancel.png"] forState: UIControlStateSelected];
        _cancelButton.showsTouchWhenHighlighted = YES;
        //[_cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        
        
        _loadProgress = [[UIProgressView alloc] init];
        _loadProgress.frame = CGRectMake(55.0f, 50.0f, 200.0f, 15.0f);
        _loadProgress.progress = playlistItem.loadProgress;
        //NSLog(@"Load progress = %f", playlistItem.loadProgress);
        if(playlistItem.loadProgress != 1.0) {
            if(playlistItem.loadProgress == 0.0) {
                [self.contentView addSubview:_waitingView];
            } else {
                [self.contentView addSubview:_loadProgress];
            }
            // We can only cancel once the looping begins in music upload code.
            if (!playlistItem.cancelled && playlistItem.belongsToUser == YES) {
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
    [_cancelButton removeFromSuperview];
    NSLog(@"Cancelled an upload.");
    [self.delegate cancelMusicAndUpdateAll:_playlistItem];
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
