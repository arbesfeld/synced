//
//  MenuViewController.h
//  AirShare2
//
//  Created by mata on 4/29/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "Game.h"
#import "UIButton+Extensions.h"

#import <UIKit/UIKit.h>

@interface MenuViewController : UIViewController <UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *usersTable;
@property (weak, nonatomic) IBOutlet UILabel *connectedUsersLabel;
@property (weak, nonatomic) IBOutlet UIButton *syncButton;
@property (nonatomic, strong) Game *game;
@property (weak, nonatomic) IBOutlet UIImageView *sepeartorImageView;

- (IBAction)syncButtonPressed:(id)sender;

@end
