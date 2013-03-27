#import "GameViewController.h"

@interface GameViewController ()


@end

@implementation GameViewController
{
    UIAlertView *_alertView;
}
@synthesize delegate = _delegate;
@synthesize game = _game;

@synthesize songLabel = _songLabel;
@synthesize artistLabel = _artistLabel;

- (void)dealloc
{
#ifdef DEBUG
	NSLog(@"dealloc %@", self);
#endif
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    _currentPlaylistItem = [[PlaylistItem alloc] initPlaylistItemWithName:@"No Songs Playing" andSubtitle:@"" andID:@"" andPlaylistItemType:PlaylistItemTypeNone];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
	[_alertView dismissWithClickedButtonIndex:_alertView.cancelButtonIndex animated:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Actions

- (IBAction)exitAction:(id)sender
{
	if (self.game.isServer)
	{
		_alertView = [[UIAlertView alloc]
                      initWithTitle:NSLocalizedString(@"End Game?", @"Alert title (user is host)")
                      message:NSLocalizedString(@"This will terminate the game for all other players.", @"Alert message (user is host)")
                      delegate:self
                      cancelButtonTitle:NSLocalizedString(@"No", @"Button: No")
                      otherButtonTitles:NSLocalizedString(@"Yes", @"Button: Yes"),
                      nil];
        
		[_alertView show];
	}
	else
	{
		_alertView = [[UIAlertView alloc]
                      initWithTitle: NSLocalizedString(@"Leave Game?", @"Alert title (user is not host)")
                      message:nil
                      delegate:self
                      cancelButtonTitle:NSLocalizedString(@"No", @"Button: No")
                      otherButtonTitles:NSLocalizedString(@"Yes", @"Button: Yes"),
                      nil];
        
		[_alertView show];
	}
}

#pragma mark - GameDelegate

- (void)game:(Game *)game didQuitWithReason:(QuitReason)reason
{
	[self.delegate gameViewController:self didQuitWithReason:reason];
}

- (void)gameWaitingForServerReady:(Game *)game
{
}
- (void)gameWaitingForClientsReady:(Game *)game
{
}

- (void)gameServer:(Game *)server clientDidConnect:(Player *)player;
{
    [self.userTable reloadData];
    [self.playlistTable reloadData];
}

- (void)gameServer:(Game *)server clientDidDisconnect:(Player *)player;
{
    [self.userTable reloadData];
    [self.playlistTable reloadData];
}

- (void)reloadTable
{
    _game.playlist = [NSMutableArray arrayWithArray:[_game.playlist sortedArrayUsingSelector:@selector(compare:)]];
    [self.userTable reloadData];
    [self.playlistTable reloadData];
}

- (void)game:(Game *)game setCurrentItem:(PlaylistItem *)playlistItem
{
    _currentPlaylistItem = playlistItem;
    self.songLabel.text = playlistItem.name;
    self.artistLabel.text = playlistItem.subtitle;
}

- (void)gameServerSessionDidEnd:(Game *)server;
{
    
}

- (void)gameServerNoNetwork:(Game *)server;
{
    
}

- (PlaylistItem *)getCurrentPlaylistItem {
    return _currentPlaylistItem;
}
#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView == self.userTable) {
        if (_game != nil)
            return [_game.players count];
        else
            return 0;
    }
    // else, is the music list
    else {
        if (_game != nil)
            return [_game.playlist count];
        else
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(tableView == self.userTable) {
        if (cell == nil)
            cell = [[UITableViewCell alloc] init];
        
        NSString *peerID = [[_game.players allKeys] objectAtIndex:indexPath.row];
        cell.textLabel.text = [_game displayNameForPeerID:peerID];
    }
    // else, is the music list
    else {
        if (cell == nil) {
            cell = [[UITableViewCell alloc] init];
            PlaylistItem *selectedItem = ((PlaylistItem *)[_game.playlist objectAtIndex:indexPath.row]);
            
            cell.textLabel.text = selectedItem.name;
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.detailTextLabel.text = selectedItem.subtitle;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UIButton *upvoteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            upvoteButton.frame = CGRectMake(270.0f, 5.0f, 30.0f, 30.0f);
            [upvoteButton setTitle:@"+" forState:UIControlStateNormal];
            [upvoteButton setTag:indexPath.row * 2];
            [upvoteButton setEnabled:YES];
            [cell addSubview:upvoteButton];
            
            UILabel *upvoteLabel = [[UILabel alloc] init];
            upvoteLabel.frame = CGRectMake(235.0f, 5.0f, 30.0f, 30.0f);
            upvoteLabel.text = [NSString stringWithFormat:@"%d", [selectedItem getUpvoteCount]];
            [cell addSubview:upvoteLabel];
            
            UIButton *downvoteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            downvoteButton.frame = CGRectMake(5.0f, 5.0f, 30.0f, 30.0f);
            [downvoteButton setTitle:@"-" forState:UIControlStateNormal];
            [downvoteButton setTag:indexPath.row * 2 + 1];
            [downvoteButton setEnabled:YES];
            [cell addSubview:downvoteButton];
            
            UILabel *downvoteLabel = [[UILabel alloc] init];
            downvoteLabel.frame = CGRectMake(50.0f, 5.0f, 30.0f, 30.0f);
            downvoteLabel.text = [NSString stringWithFormat:@"%d", [selectedItem getDownvoteCount]];
            [cell addSubview:downvoteLabel];
            
            [upvoteButton addTarget:self
                          action:@selector(upvoteButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
            
            [downvoteButton addTarget:self
                           action:@selector(downvoteButtonPressed:)
                 forControlEvents:UIControlEventTouchUpInside];
        }
    }
    return cell;
}

- (IBAction)upvoteButtonPressed:(id)sender
{
    UIButton *upvoteButton = ((UIButton *)sender);
    NSLog(@"tag: %d", upvoteButton.tag);
    PlaylistItem *selectedItem = ((PlaylistItem *)[_game.playlist objectAtIndex:upvoteButton.tag / 2]);
    [selectedItem upvote:1];
    [upvoteButton setEnabled:NO];
    
    // find other button and enable it
    // because of how we intialized tags, the tag is one more than the upvote tag
    UITableViewCell *cell = (UITableViewCell *)[upvoteButton superview];
    UIButton *downvoteButton = (UIButton *)[cell viewWithTag:upvoteButton.tag / 2 + 1];
    if(![downvoteButton isEnabled]) {
        // user no longer wants it to be downvoted
        [selectedItem downvote:-1];
        [_game sendVotePacketForItem:selectedItem andAmount:-1 upvote:NO];
        [downvoteButton setEnabled:YES];
    }
    
    [_game sendVotePacketForItem:selectedItem andAmount:1 upvote:YES];
    [self reloadTable];
}

- (IBAction)downvoteButtonPressed:(id)sender
{
    UIButton *downvoteButton = ((UIButton *)sender);
    PlaylistItem *selectedItem = ((PlaylistItem *)[_game.playlist objectAtIndex:downvoteButton.tag / 2]);
    [selectedItem downvote:1];
    [downvoteButton setEnabled:NO];
    
    // find other button and enable it
    // because of how we intialized tags, the tag is one less than the downvote tag
    UITableViewCell *cell = (UITableViewCell *)[downvoteButton superview];
    UIButton *upvoteButton = (UIButton *)[cell viewWithTag:downvoteButton.tag / 2 - 1];
    if(![upvoteButton isEnabled]) {
        // user no longer wants it to be upvoted
        [selectedItem upvote:-1];
        [_game sendVotePacketForItem:selectedItem andAmount:-1 upvote:YES];
        [upvoteButton setEnabled:YES];
    }
    
    [_game sendVotePacketForItem:selectedItem andAmount:1 upvote:NO];
    [self reloadTable];
}
#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != alertView.cancelButtonIndex)
	{
		[self.game quitGameWithReason:QuitReasonUserQuit];
	}
}

#pragma mark - playMusic____
- (IBAction)playMusic:(id)sender {
    MPMediaPickerController *mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAny];
    mediaPicker.delegate = self;
    mediaPicker.allowsPickingMultipleItems = NO;
    mediaPicker.prompt = @"Select song to play";
    
    [self presentViewController:mediaPicker animated:YES completion:nil];
}

- (void) mediaPicker: (MPMediaPickerController *)mediaPicker didPickMediaItems: (MPMediaItemCollection *) mediaItemCollection
{
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
    
    if (mediaItemCollection) {
        
        MPMediaItem *chosenItem = mediaItemCollection.items[0];
        
        NSURL *songURL = [chosenItem valueForProperty: MPMediaItemPropertyAssetURL];
        NSLog(@"url = %@", songURL);
        [_game uploadMusicWithMediaItem:chosenItem];
    }
}

- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker
{
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}
@end
