#import "GameViewController.h"
#import "PlaylistItemCell.h"

const double epsilon = 0.02;

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
    
    if(tableView == self.userTable) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] init];
            NSString *peerID = [[_game.players allKeys] objectAtIndex:indexPath.row];
            cell.textLabel.text = [_game displayNameForPeerID:peerID];
        }
        return cell;
    }
    // else, is the playlist
    else {
        PlaylistItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        PlaylistItem *selectedItem = ((PlaylistItem *)[_game.playlist objectAtIndex:indexPath.row]);
        if (cell == nil) {
            cell = [[PlaylistItemCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil playlistItem:selectedItem voteValue:[[_voteAmount objectForKey:selectedItem.ID] intValue]];
            cell.delegate = self;
        }
        return cell;
    }
}


#pragma mark - UITableViewDelegate

#pragma mark - PlaylistItemDelegate

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
