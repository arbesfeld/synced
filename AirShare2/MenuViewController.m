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
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

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
    return cell;
}

- (IBAction)syncButtonPressed:(id)sender {
    [_game sendSyncPacketsForItem:(MediaItem *)_game.currentItem];
}
@end
