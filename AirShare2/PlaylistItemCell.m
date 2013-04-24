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

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier playlistItem:(PlaylistItem *)playlistItem voteValue:(int)voteValue position:(int)position
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        static float alpha = 0.5;
        const NSArray *colorTable = [[NSArray alloc] initWithObjects: [UIColor colorWithRed:254/255.0 green:219/255.0 blue:114/255.0 alpha:alpha],[UIColor colorWithRed:165/255.0 green:254/225.0 blue:113/225.0 alpha:alpha], [UIColor colorWithRed:113/255.0 green:254/225.0 blue:146/225.0 alpha:alpha], [UIColor colorWithRed:113/255.0 green:169/225.0 blue:254/225.0 alpha:alpha], [UIColor colorWithRed:113/255.0 green:254/225.0 blue:235/225.0 alpha:alpha], [UIColor colorWithRed:113/255.0 green:115/225.0 blue:254/225.0 alpha:alpha], [UIColor colorWithRed:188/255.0 green:113/225.0 blue:254/225.0 alpha:alpha], [UIColor colorWithRed:254/255.0 green:113/225.0 blue:188/225.0 alpha:alpha], [UIColor colorWithRed:254/255.0 green:165/225.0 blue:113/225.0 alpha:alpha], [UIColor colorWithRed:254/255.0 green:115/225.0 blue:113/225.0 alpha:alpha], nil];
        
        self.position = position+1;
        self.playlistItem = playlistItem;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        //self.textLabel.font = [UIFont systemFontOfSize:17.0f];
        self.textLabel.text = playlistItem.name;
        self.textLabel.font = [UIFont fontWithName:@"CenturyGothicStd" size:14];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.textAlignment = NSTextAlignmentLeft;
        
        self.detailTextLabel.text = playlistItem.subtitle;
        self.detailTextLabel.font = [UIFont fontWithName:@"CenturyGothicStd" size:11];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        self.detailTextLabel.textColor = [UIColor darkGrayColor];
        
        self.positionLabel = [[UILabel alloc] init];
        self.positionLabel.frame = CGRectMake(2.0f, 10.0f, 30.0f, 30.0f);
        self.positionLabel.text = [NSString stringWithFormat:@"%d.", self.position];
        self.positionLabel.font = [UIFont fontWithName:@"CenturyGothicStd-Bold" size:15];
        self.positionLabel.backgroundColor = [UIColor clearColor];
        self.positionLabel.textAlignment = NSTextAlignmentCenter;
        
        
        if(playlistItem.playlistItemType == PlaylistItemTypeSong) {
            _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(28.0f, 6.0f, 30.0f, 30.0f)];
            _iconView.image = [UIImage imageNamed:@"music symbol-01"];
        } else {
            _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(31.0f, 9.0f, 25.0f, 25.0f)];
            _iconView.image = [UIImage imageNamed:@"movies-01"];
        }
        [_iconView setAlpha:0.8];
        _iconView.layer.shadowColor = [UIColor blackColor].CGColor;
        _iconView.layer.shadowOffset = CGSizeMake(0, 0.5);
        _iconView.layer.shadowOpacity = 1;
        _iconView.layer.shadowRadius = 0.5;
        
        // set status of buttons
        _upvotePressed = YES;
        
        NSString *upvoteString;
        if(voteValue > 0) {
            upvoteString = @"upvote_selected.png";
        } else {
            _upvotePressed = NO;
            upvoteString = @"upvote.png";
        }
        _upvoteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _upvoteButton.frame = CGRectMake(269.0f, -8.0f, 45.0f, 45.0f);
        [_upvoteButton setBackgroundImage:[UIImage imageNamed:upvoteString] forState: UIControlStateNormal];
        [_upvoteButton setBackgroundImage:[UIImage imageNamed:upvoteString] forState: UIControlStateHighlighted];
        [_upvoteButton setBackgroundImage:[UIImage imageNamed:upvoteString] forState: UIControlStateSelected];
        _upvoteButton.showsTouchWhenHighlighted = YES;
        [_upvoteButton setHitTestEdgeInsets:UIEdgeInsetsMake(-5, -20, -5, -5)];
        
        self.upvoteLabel = [[UILabel alloc] init];
        _upvoteLabel.frame = CGRectMake(288.0f, 11.0f, 15.0f, 30.0f);
        _upvoteLabel.font = [UIFont fontWithName:@"Century Gothic" size:12.0f];
        _upvoteLabel.text = [NSString stringWithFormat:@"%d", [playlistItem getUpvoteCount]];
        _upvoteLabel.backgroundColor = [UIColor clearColor];
        
        _downvoteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _downvoteButton.frame = CGRectMake(280.0f, 5.0f, 35.0f, 35.0f);
        _downvoteButton.imageView.contentMode = UIViewContentModeCenter;
        _downvoteButton.imageView.bounds = CGRectMake(293.0f, 10.0f, 28.0f, 28.0f);
        [_downvoteButton setBackgroundImage:[UIImage imageNamed:@"downvote.png"] forState: UIControlStateNormal];
        [_downvoteButton setBackgroundImage:[UIImage imageNamed:@"downvote.png"] forState: UIControlStateHighlighted];
        [_downvoteButton setBackgroundImage:[UIImage imageNamed:@"downvote.png"] forState: UIControlStateSelected];
        [_downvoteButton setBackgroundImage:[UIImage imageNamed:@"downvote_selected.png"] forState: UIControlStateDisabled];
        _downvoteButton.showsTouchWhenHighlighted = YES;
        //[_downvoteButton setTitle:@"-" forState:UIControlStateNormal];
        //[_downvoteButton setEnabled:downvoteButtonEnabled];
        
        self.downvoteLabel = [[UILabel alloc] init];
        _downvoteLabel.frame = CGRectMake(293.0f, 25.0f, 15.0f, 30.0f);
        _downvoteLabel.font = [UIFont fontWithName:@"Century Gothic" size:16.0f];
        _downvoteLabel.text = [NSString stringWithFormat:@"%d", [playlistItem getDownvoteCount]];
        _downvoteLabel.backgroundColor = [UIColor clearColor];

        NSURL *url = [[NSBundle mainBundle] URLForResource:@"loading" withExtension:@"gif"];
        _waitingView = [[UIImageView alloc] initWithFrame:CGRectMake(10.0f, 16.0f, 12.0f, 12.0f)];
        _waitingView.image = [UIImage animatedImageWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
        
        _cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _cancelButton.frame = CGRectMake(266.0f, 0.0f, 50.0f, 50.0f);
        [_cancelButton setBackgroundImage:[UIImage imageNamed:@"cancel.png"] forState: UIControlStateNormal];
        [_cancelButton setBackgroundImage:[UIImage imageNamed:@"cancel.png"] forState: UIControlStateHighlighted];
        [_cancelButton setBackgroundImage:[UIImage imageNamed:@"cancel.png"] forState: UIControlStateSelected];
        _cancelButton.showsTouchWhenHighlighted = YES;
        //[_cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        
        _loadProgress = [[UIView alloc] init];
        NSString *gradientLocation = [[NSBundle mainBundle] pathForResource:@"gradient_transparent" ofType:@"png"];
        _gradientLoadProgress = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:gradientLocation]];
        [_gradientLoadProgress setAlpha:0.25];
        [_loadProgress addSubview:_gradientLoadProgress];
        _loadProgress.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width * playlistItem.previousLoadProgress, self.frame.size.height+1);
        _gradientLoadProgress.frame = _loadProgress.frame;
        
        if(self.playlistItem.loadProgress != 0.0 && (self.playlistItem.loadProgress != 1.0 || self.playlistItem.previousLoadProgress != 1.0)) {
            _updateLoadProgress = [NSTimer timerWithTimeInterval:0.01
                                                          target:self
                                                        selector:@selector(handleLoadProgress:)
                                                        userInfo:nil
                                                         repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:_updateLoadProgress forMode:NSRunLoopCommonModes];
        }
        _loadProgress.layer.borderColor = [UIColor grayColor].CGColor;
        _loadProgress.layer.borderWidth = 1.0f;
        _loadProgress.autoresizingMask = 0x3f;
        
        int colorID = position % colorTable.count;
        UIColor *originalColor = (UIColor *)colorTable[colorID];
        _loadProgress.backgroundColor = originalColor;
        
        // this item was voted on, transition from its original color
        if(self.playlistItem.justVoted) {
            CGFloat hue, saturation, brightness, alpha;
            [originalColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
            UIColor *flashedColor = [UIColor colorWithHue:hue saturation:MIN(1.0, saturation + 0.25) brightness:MAX(0.0, brightness - 0.1) alpha:alpha];
            
            [UIView animateWithDuration:0.4 animations:^ {
                self.loadProgress.backgroundColor = flashedColor;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.4 animations:^ {
                    _loadProgress.backgroundColor = originalColor;
                }];
            }];
            self.playlistItem.justVoted = NO;
        }
        
        // place behind other views
        
        [self.contentView addSubview:_iconView];
        //NSLog(@"Load progress = %f", playlistItem.loadProgress);
        if(playlistItem.loadProgress != 1.0) {
            if(playlistItem.loadProgress == 0.0) {
                [self.contentView addSubview:_waitingView];
            } else {
                // add load progress to back of cell
                [self.contentView insertSubview:_loadProgress atIndex:0];
            }
            // We can only cancel once the looping begins in music upload code.
            if (!playlistItem.cancelled && playlistItem.uploadedByUser == YES) {
                [self.contentView addSubview:_cancelButton];
            }
        } else {
            // add load progress to back of cell
            [self.contentView insertSubview:_loadProgress atIndex:0];
            [self.contentView addSubview:_positionLabel];
            [self.contentView addSubview:_upvoteButton];
            [self.contentView bringSubviewToFront:_upvoteButton];
            [self.contentView addSubview:_upvoteLabel];
            //[self.contentView addSubview:_downvoteButton];
            //[self.contentView addSubview:_downvoteLabel];
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
- (void)handleLoadProgress:(NSTimer *)timer {
    float newLoadProgress = (self.playlistItem.loadProgress + 9*self.playlistItem.previousLoadProgress) / 10.0;
    // if it's very close to load progress, just set it equal to loadProgress
    if(self.playlistItem.loadProgress - newLoadProgress < 0.01) {
        newLoadProgress = self.playlistItem.loadProgress;
    }
    CGRect frame = self.loadProgress.frame;
    frame.size.width =  self.frame.size.width * newLoadProgress;
    _loadProgress.frame = frame;
    _gradientLoadProgress.frame = _loadProgress.frame;
    self.playlistItem.previousLoadProgress = newLoadProgress;
    if(newLoadProgress == 1.0) {
        [timer invalidate];
    }
}
- (IBAction)upvoteButtonPressed:(id)sender
{
    NSLog(@"Pressed");
    //[_upvoteButton setEnabled:NO];
    if(_upvotePressed) {
        // unpress it
        NSLog(@"Yes");
        _upvotePressed = NO;
        [self.delegate voteForItem:_playlistItem withValue:-1 upvote:YES];
        _upvoteButton.imageView.image = [UIImage imageNamed:@"upvote.png"];
    } else {
        NSLog(@"No");
        _upvotePressed = YES;
        [self.delegate voteForItem:_playlistItem withValue:1 upvote:YES];
        _upvoteButton.imageView.image = [UIImage imageNamed:@"upvote_selected.png"];
    }
//    if(![_downvoteButton isEnabled]) {
//        // user no longer wants it to be downvoted
//        [self.delegate voteForItem:_playlistItem withValue:-1 upvote:NO];
//        
//        [_downvoteButton setEnabled:YES];
//    }
    self.playlistItem.justVoted = YES;
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
    self.playlistItem.justVoted = YES;
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.textLabel.frame = CGRectMake(65.0f, self.textLabel.frame.origin.y+2, self.frame.size.width - 110.0f, self.textLabel.frame.size.height);
    self.detailTextLabel.frame = CGRectMake(65.0f, self.detailTextLabel.frame.origin.y+2, self.frame.size.width - 115.0f, self.detailTextLabel.frame.size.height);
}
@end
