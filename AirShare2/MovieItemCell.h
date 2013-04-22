//
//  MovieItemCell.h
//  AirShare2
//
//  Created by mata on 4/16/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>

#import "UIImageView+WebCache.h"

@interface MovieItemCell : UITableViewCell 

@property (nonatomic, strong) MPMediaItem *movieItem;
@property (nonatomic, strong) NSString *title, *artist, *duration;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) UIImageView *thumbImgView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier movieItem:(MPMediaItem *)movieItem;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier title:(NSString *)title artist:(NSString *)artist duration:(NSString *)duration imageURL:(NSURL *)url;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier title:(NSString *)title artist:(NSString *)artist duration:(NSString *)duration image:(UIImage *)image;

@end
