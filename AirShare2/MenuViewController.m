//
//  MenuViewController.m
//  AirShare2
//
//  Created by mata on 4/29/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "MenuViewController.h"

@interface MenuViewController ()

@end

@implementation MenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self.syncButton setHitTestEdgeInsets:UIEdgeInsetsMake(-50, -50, -50, -200)];
        self.syncButton.showsTouchWhenHighlighted = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.usersTable setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    _usersTable.backgroundColor = [UIColor clearColor];
    if(!IS_PHONE) {
        [self.background setImage:[UIImage imageNamed:@"BGIpad.png"]];
    } else if(IS_IPHONE_5) {
        [self.background setImage:[UIImage imageNamed:@"metalHolesIP5.png"]];
    } else {
        [self.background setImage:[UIImage imageNamed:@"metalHolesIP4.png"]];
    }
    _connectedUsersLabel.font = [UIFont fontWithName:@"CenturyGothicStd-Bold" size:17.0f];
    _resyncLabel.font = [UIFont fontWithName:@"Century Gothic" size:16.0f];
    _sepeartorImageView.backgroundColor = [UIColor blackColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 24;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(_game) {
        return _game.players.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    
    NSString *peerID = [[_game.players allKeys] objectAtIndex:indexPath.row];
    cell.textLabel.text = [_game displayNameForPeerID:peerID];
    cell.textLabel.font = [UIFont fontWithName:@"Century Gothic" size:15.0f];
    cell.textLabel.textColor = [UIColor whiteColor];
    UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
    backView.backgroundColor = [UIColor clearColor];
    cell.backgroundView = backView;
    
    return cell;
}

- (IBAction)syncButtonPressed:(id)sender {
    [_game updateServerStats:9];
    [_game sendSyncPacketsForItem:(MediaItem *)_game.currentItem];
}
@end
