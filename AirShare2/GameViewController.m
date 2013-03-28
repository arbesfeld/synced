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
    // visual placeholder
    _currentPlaylistItem = [[PlaylistItem alloc] initPlaylistItemWithName:@"No Songs Playing" andSubtitle:@"" andID:@"000000" andPlaylistItemType:PlaylistItemTypeNone];
    _voteAmount = [[NSMutableDictionary alloc] initWithCapacity:10];
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

- (void)setPlaybackProgress:(double)f {
    self.playbackProgressBar.progress = f;
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
        }
        
        PlaylistItem *selectedItem = ((PlaylistItem *)[_game.playlist objectAtIndex:indexPath.row]);
        
        // set status of buttons
        BOOL upvoteButtonEnabled = YES;
        BOOL downvoteButtonEnabled = YES;
        int voteValue = [[_voteAmount objectForKey:selectedItem.ID] intValue];
        if(voteValue > 0) {
            upvoteButtonEnabled = NO;
        } else if(voteValue < 0) {
            downvoteButtonEnabled = NO;
        }
        
        cell.textLabel.text = selectedItem.name;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.detailTextLabel.text = selectedItem.subtitle;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIButton *upvoteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        upvoteButton.frame = CGRectMake(270.0f, 5.0f, 30.0f, 30.0f);
        [upvoteButton setTitle:@"+" forState:UIControlStateNormal];
        [upvoteButton setTag:100];
        [upvoteButton setEnabled:upvoteButtonEnabled];
        [cell.contentView addSubview:upvoteButton];
        
        UILabel *upvoteLabel = [[UILabel alloc] init];
        upvoteLabel.frame = CGRectMake(235.0f, 5.0f, 30.0f, 30.0f);
        upvoteLabel.text = [NSString stringWithFormat:@"%d", [selectedItem getUpvoteCount]];
        [cell.contentView addSubview:upvoteLabel];
        
        UIButton *downvoteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        downvoteButton.frame = CGRectMake(5.0f, 5.0f, 30.0f, 30.0f);
        [downvoteButton setTitle:@"-" forState:UIControlStateNormal];
        [downvoteButton setTag:101];
        [downvoteButton setEnabled:downvoteButtonEnabled];
        [cell.contentView addSubview:downvoteButton];
        
        UILabel *downvoteLabel = [[UILabel alloc] init];
        downvoteLabel.frame = CGRectMake(50.0f, 5.0f, 30.0f, 30.0f);
        downvoteLabel.text = [NSString stringWithFormat:@"%d", [selectedItem getDownvoteCount]];
        [cell.contentView addSubview:downvoteLabel];
        
        [upvoteButton addTarget:self
                      action:@selector(upvoteButtonPressed:)
            forControlEvents:UIControlEventTouchUpInside];
        
        [downvoteButton addTarget:self
                       action:@selector(downvoteButtonPressed:)
             forControlEvents:UIControlEventTouchUpInside];
        
        
    }
    return cell;
}

- (IBAction)upvoteButtonPressed:(id)sender
{
    UIButton *upvoteButton = ((UIButton *)sender);
    [upvoteButton setEnabled:NO];
    
    UITableViewCell *cell = (UITableViewCell *)[[upvoteButton superview] superview];
    NSIndexPath *indexPath = [_playlistTable indexPathForCell:cell];
    PlaylistItem *selectedItem = (PlaylistItem *)[_game.playlist objectAtIndex:indexPath.row];
    [self voteForItem:selectedItem withValue:1 upvote:YES];
    
    // 101 set as downvote tag
    UIButton *downvoteButton = (UIButton *)[cell.contentView viewWithTag:101];
    if(![downvoteButton isEnabled]) {
        // user no longer wants it to be downvoted
        [self voteForItem:selectedItem withValue:-1 upvote:NO];
        
        [downvoteButton setEnabled:YES];
    }
    [self reloadTable];
}

- (IBAction)downvoteButtonPressed:(id)sender
{
    UIButton *downvoteButton = ((UIButton *)sender);
    [downvoteButton setEnabled:NO];
    
    UITableViewCell *cell = (UITableViewCell *)[[downvoteButton superview] superview];
    NSIndexPath *indexPath = [_playlistTable indexPathForCell:cell];
    PlaylistItem *selectedItem = (PlaylistItem *)[_game.playlist objectAtIndex:indexPath.row];
    [self voteForItem:selectedItem withValue:1 upvote:NO];
    
    // 100 set as upvote tag
    UIButton *upvoteButton = (UIButton *)[cell.contentView viewWithTag:100];
    if(![upvoteButton isEnabled]) {
        // user no longer wants it to be upvoted
        [self voteForItem:selectedItem withValue:-1 upvote:YES];
    }
    [self reloadTable];
}

// value is a int that represents the weight of the vote
- (void)voteForItem:(PlaylistItem *)playlistItem withValue:(int)value upvote:(BOOL)upvote {
    if(upvote) {
        [playlistItem upvote:value];
        [self addValue:[NSNumber numberWithInt:value] forID:playlistItem.ID];
    } else {
        [playlistItem downvote:value];
        [self addValue:[NSNumber numberWithInt:-value] forID:playlistItem.ID];
    }
    [self.game sendVotePacketForItem:playlistItem andAmount:value upvote:upvote];
}

- (void)addValue:(NSNumber *)value forID:(NSString *)ID {
    NSNumber *prevAmount = [_voteAmount objectForKey:ID];
    if(prevAmount) {
        [_voteAmount setObject:[NSNumber numberWithInt:([value intValue] + [prevAmount intValue])]
                        forKey:ID];
    }
    else {
        [_voteAmount setObject:value forKey:ID];
    }
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
