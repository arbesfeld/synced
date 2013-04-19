//
//  MovieItemCell.m
//  AirShare2
//
//  Created by mata on 4/16/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "MovieItemCell.h"
#import <AVFoundation/AVFoundation.h>
@implementation MovieItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier movieItem:(MPMediaItem *)movieItem
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.movieItem = movieItem;
        
        [self performSelector:@selector(loadImage:) withObject:@YES afterDelay:0];
        
        _title = [self.movieItem valueForProperty:MPMediaItemPropertyTitle];
        _artist = [self.movieItem valueForProperty:MPMediaItemPropertyArtist];
        NSNumber *duration = [self.movieItem valueForProperty:MPMediaItemPropertyPlaybackDuration];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(91, 12, 220, 20)];
        titleLabel.text = _title;
        titleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
        UILabel *artistLabel = [[UILabel alloc] initWithFrame:CGRectMake(91, 33, 220, 20)];
        artistLabel.text = _artist;
        artistLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        
        UILabel *durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(91, 52, 220, 20)];
        int minutes = [duration intValue] / 60;
        int seconds = [duration intValue] % 60;
        
        if(seconds < 10) {
            durationLabel.text = [NSString stringWithFormat:@"%d:0%d", minutes, seconds];
        } else {
            durationLabel.text = [NSString stringWithFormat:@"%d:%d", minutes, seconds];
        }
        durationLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        durationLabel.textColor = [UIColor grayColor];
        
        [self.contentView addSubview:titleLabel];
        [self.contentView addSubview:artistLabel];
        [self.contentView addSubview:durationLabel];
    }
    return self;
}

- (void)loadImage:(BOOL)load
{
    if(!load) {
        return;
    }
    NSURL *url = [self.movieItem valueForProperty:MPMediaItemPropertyAssetURL];
    AVURLAsset *asset= [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    CMTime time = CMTimeMake(30, 1);
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbImg = [UIImage imageWithCGImage:imageRef];
    UIImageView *thumbImgView = [[UIImageView alloc] initWithImage:thumbImg];
    thumbImgView.contentMode = UIViewContentModeScaleAspectFit;
    thumbImgView.frame = CGRectMake(0, 0, 80, 80);
    thumbImgView.backgroundColor = [UIColor blackColor];
    [self.contentView addSubview:thumbImgView];
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
    [self.contentView setNeedsLayout];
    [thumbImgView setNeedsLayout];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
