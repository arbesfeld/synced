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
        
        _imageURL = [self.movieItem valueForProperty:MPMediaItemPropertyAssetURL];
        int minutes = [duration intValue] / 60;
        int seconds = [duration intValue] % 60;
        
        if(seconds < 10) {
            _duration = [NSString stringWithFormat:@"%d:0%d", minutes, seconds];
        } else {
            _duration = [NSString stringWithFormat:@"%d:%d", minutes, seconds];
        }
        [self loadContent];
    }
    return self;
}
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier title:(NSString *)title artist:(NSString *)artist duration:(NSString *)duration image:(UIImage *)image
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _title = title;
        _artist = artist;
        _duration = duration;
        [self loadContent];
        [_thumbImgView setImage:image];
        [_thumbImgView setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier title:(NSString *)title artist:(NSString *)artist duration:(NSString *)duration imageURL:(NSURL *)url
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _title = title;
        _artist = artist;
        _duration = duration;
        _imageURL = url;
        [self loadContent];
        [_thumbImgView setImageWithURL:_imageURL placeholderImage:nil];
    }
    return self;
}

- (void)loadContent
{
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(91, 10, 220, 20)];
    titleLabel.text = _title;
    titleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    UILabel *artistLabel = [[UILabel alloc] initWithFrame:CGRectMake(91, 30, 220, 20)];
    artistLabel.text = _artist;
    artistLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    UILabel *durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(91, 50, 220, 20)];
    durationLabel.text = _duration;
    durationLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    durationLabel.textColor = [UIColor grayColor];
    
    _thumbImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    _thumbImgView.contentMode = UIViewContentModeScaleAspectFit;
    _thumbImgView.backgroundColor = [UIColor blackColor];
    
    [self.contentView addSubview:_thumbImgView];
    
    [self.contentView addSubview:titleLabel];
    [self.contentView addSubview:artistLabel];
    [self.contentView addSubview:durationLabel];
}
- (void)loadImage:(BOOL)load
{
    if(!load) {
        return;
    }
    AVURLAsset *asset= [[AVURLAsset alloc] initWithURL:_imageURL options:nil];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    CMTime time = CMTimeMake(30, 1);
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbImg = [UIImage imageWithCGImage:imageRef];
    _thumbImgView.image = thumbImg;
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
