//
//  MovieItemCell.h
//  AirShare2
//
//  Created by mata on 4/16/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>

@interface MovieItemCell : UITableViewCell

@property (nonatomic, strong) MPMediaItem *movieItem;
@property (nonatomic, strong) NSString *title, *artist;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

- (void)addContent;
@end
