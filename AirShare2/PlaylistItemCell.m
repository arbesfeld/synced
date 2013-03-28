//
//  PlaylistItemCell.m
//  AirShare2
//
//  Created by mata on 3/28/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PlaylistItemCell.h"

@implementation PlaylistItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
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
