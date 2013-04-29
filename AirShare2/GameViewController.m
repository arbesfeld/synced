#import "GameViewController.h"
#import "PlaylistItemCell.h"
#import "MoviePickerViewController.h"

@implementation GameViewController
{
    UIAlertView *_alertView;
    int _itemNumber;
}
@synthesize delegate = _delegate;
@synthesize game = _game;


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
    
//    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 60, self.view.bounds.size.width, 1.5)];
//    lineView.backgroundColor = [UIColor colorWithHue:1.0 saturation:0.0 brightness:.6 alpha:.8];
//    [self.view addSubview:lineView];
    
    _menuViewController.game = _game;
    [_menuViewController.usersTable reloadData];
    
    _hasVotedForItem = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    self.view.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"bgGreyImg.png"]];
    //self.playlistTable.layer.cornerRadius = 12;
    self.playlistTable.layer.masksToBounds = YES;

    //self.playlistTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    _canLoadView = YES;
    _itemNumber = 0;
    
    [self isWaiting:YES];
    
    [self.skipSongButton setHitTestEdgeInsets:UIEdgeInsetsMake(-10, -10, -10, -10)];
    
    self.waitingLabel.font = [UIFont fontWithName:@"Century Gothic" size:14.0f];
    self.waitingLabel.textColor = [UIColor darkGrayColor];
    
    self.playingLabel.font = [UIFont fontWithName:@"Century Gothic" size:11.0f];
    self.playingLabel.textColor = [UIColor darkGrayColor];
    
    self.partyModeLabel.hidden = true;
    self.partyModeLabel.font = [UIFont fontWithName:@"Century Gothic" size:11.0f];
    self.partyModeLabel.textColor = [UIColor darkGrayColor];
    
    self.songTitle.shadowOffset = CGSizeMake(0.0, -1.0);
    self.songTitle.textColor = [UIColor colorWithRed:0.234 green:0.234 blue:0.234 alpha:1.000];
    self.songTitle.backgroundColor = [UIColor clearColor];
    self.songTitle.font = [UIFont fontWithName:@"Century Gothic" size:16.0f];
    
    self.artistLabel.font = [UIFont fontWithName:@"Century Gothic" size:12.0f];
    self.artistLabel.textColor = [UIColor darkGrayColor];
    
    self.skipsLabel.font = [UIFont fontWithName:@"Century Gothic" size:12.0f];
    self.skipsLabel.textColor = [UIColor darkGrayColor];
    
    self.skipSongLabel.font = [UIFont fontWithName:@"Century Gothic" size:16.0f];
    self.skipSongLabel.textColor = [UIColor colorWithRed:0.234 green:0.234 blue:0.234 alpha:1.000];
    
    self.timeLabel.font = [UIFont fontWithName:@"Century Gothic" size:16.0f];
    self.timeLabel.textColor = [UIColor colorWithRed:0.234 green:0.234 blue:0.234 alpha:1.000];
    
    self.playlistTable.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [self initialCheckVolume];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    
}
    
- (void)isWaiting:(BOOL)isWaiting
{
    self.waitingLabel.hidden = !isWaiting;
    self.playingLabel.hidden = isWaiting;
    self.songTitle.hidden = isWaiting;
    self.artistLabel.hidden = isWaiting;
    self.skipSongButton.hidden = isWaiting;
    self.skipSongLabel.hidden = isWaiting;
    self.timeLabel.hidden = isWaiting;
    self.playbackProgressBar.hidden = isWaiting;
    self.skipsLabel.hidden = isWaiting;
    self.partyModeLabel.hidden = isWaiting;
    self.partySwitch.hidden = isWaiting;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        _menuViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
        self.slidingViewController.underLeftViewController = _menuViewController;
    }
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    [self.slidingViewController setAnchorRightRevealAmount:280.0f];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}
- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[_alertView dismissWithClickedButtonIndex:_alertView.cancelButtonIndex animated:NO];
    [self resignFirstResponder];
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
                      initWithTitle:NSLocalizedString(@"End Session?", @"Alert title (user is host)")
                      message:NSLocalizedString(@"This will terminate the session for all other players.", @"Alert message (user is host)")
                      delegate:self
                      cancelButtonTitle:NSLocalizedString(@"No", @"Button: No")
                      otherButtonTitles:NSLocalizedString(@"Yes", @"Button: Yes"),
                      nil];
        
		[_alertView show];
	}
	else
	{
		_alertView = [[UIAlertView alloc]
                      initWithTitle: NSLocalizedString(@"Leave Session?", @"Alert title (user is not host)")
                      message:nil
                      delegate:self
                      cancelButtonTitle:NSLocalizedString(@"No", @"Button: No")
                      otherButtonTitles:NSLocalizedString(@"Yes", @"Button: Yes"),
                      nil];
        
		[_alertView show];
	}
}

#pragma mark - GameDelegate

- (void)didQuitWithReason:(QuitReason)reason
{
	[self.delegate gameViewController:self didQuitWithReason:reason];
}

- (void)clientDidConnect:(Player *)player;
{
    [_menuViewController.usersTable reloadData];
    [self.playlistTable reloadData];
}

- (void)clientDidDisconnect:(Player *)player;
{
    [_menuViewController.usersTable reloadData];
    [self.playlistTable reloadData];
}

- (void)reloadTable
{
    //[self.playlistTable beginUpdates];
    NSMutableArray *newPlaylist = [NSMutableArray arrayWithArray:[_game.playlist sortedArrayUsingSelector:@selector(compare:)]];
    if([self.playlistTable numberOfRowsInSection:0] == _game.playlist.count) {
        NSLog(@"Reloading table");
        [self.playlistTable beginUpdates];
        for(int i = 0; i < _game.playlist.count; i++) {
            for(int j = 0; j < newPlaylist.count; j++) {
                if(i != j && newPlaylist[j] == _game.playlist[i]) {
                    // row moved from i to j
                    //NSLog(@"moving i = %d to j = %d", i , j);
                    [self.playlistTable moveRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]
                                               toIndexPath:[NSIndexPath indexPathForRow:j inSection:0]];
                }
            }
        }
        [self.playlistTable endUpdates];
    }
    NSLog(@"Done realoding table");
    //[self.playlistTable endUpdates];
    _game.playlist = newPlaylist;
    [self.playlistTable performSelector:@selector(reloadData) withObject:nil afterDelay:0.15];
    //[self.playlistTable reloadData];
}

- (void)reloadPlaylistItem:(PlaylistItem *)playlistItem
{
    [self.playlistTable beginUpdates];
    int loc = [self.game indexForPlaylistItem:playlistItem];
    if(loc != -1) {
        [self.playlistTable reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:loc inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }
    [self.playlistTable endUpdates];
}

- (void)addPlaylistItem:(PlaylistItem *)playlistItem
{
    playlistItem.itemNumber = _itemNumber;
    _itemNumber++;
    
    [self.playlistTable beginUpdates];
    int loc = [self.game indexForPlaylistItem:playlistItem];
    //NSLog(@"inserting at loc %d", loc);
    if(loc != -1) {
    [self.playlistTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:loc inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
    }
    
    [self.playlistTable endUpdates];
}

- (void)removePlaylistItem:(PlaylistItem *)playlistItem animation:(UITableViewRowAnimation)animation
{
    [self.playlistTable beginUpdates];
    int loc = [self.game indexForPlaylistItem:playlistItem];
    // if it will be played but not at the top, don't show an animation
    if(loc != -1) {
        if(animation == UITableViewRowAnimationTop && loc != 0) {
            [self.playlistTable deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:loc inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        } else {
            [self.playlistTable deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:loc inSection:0]] withRowAnimation:animation];
        }
        
        [self.game.playlist removeObject:playlistItem];
    }
    [self.playlistTable endUpdates];
    
    //update the row labels of the songs
    for(int i = 0; i < self.game.playlist.count; i++) {
        PlaylistItemCell *cell = (PlaylistItemCell *)[self.playlistTable cellForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
        cell.positionLabel.text = [NSString stringWithFormat:@"%d.", i+1];
    }
}

- (void)mediaFinishedPlaying
{
    [self isWaiting:YES];
    self.timeLabel.text = @"0:00";
}

- (void)secondsRemaining:(int)secondsRemaining
{
    int minutes = secondsRemaining / 60;
    int seconds = secondsRemaining - 60 * minutes;
    
    self.timeLabel.text = [NSString stringWithFormat:@"%.2d:%.2d", minutes, seconds];
}

- (void)setCurrentItem:(PlaylistItem *)playlistItem
{
    _game.currentItem = playlistItem;
    if([_game.currentItem.name isEqualToString:@""] && [_game.currentItem.subtitle isEqualToString:@""] && [_game.currentItem.ID isEqualToString:@""]) {
        // if it is the first item
        return;
    }
    
    [self isWaiting:NO];
    
    [self setHeaderWithSongName:playlistItem.name andArtistName:playlistItem.subtitle];
}

- (void)setSkipItemCount:(int)skipItemCount
{
    self.skipSongLabel.text = [NSString stringWithFormat:@"%d/%d", skipItemCount, _game.players.count];
}

- (void)gameSessionDidEnd:(Game *)server;
{
    
}

- (void)gameNoNetwork:(Game *)server;
{
}

- (void)setPlaybackProgress:(double)f {
    self.playbackProgressBar.progress = f;
    
    if(f == 0.0) {
        self.playbackProgressBar.hidden = YES;
    } else {
        self.playbackProgressBar.hidden = NO;
    }
}

- (void)showViewController:(UIViewController *)viewController
{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    // dismiss the other view controllers if they are being presented
    while([self isBeingPresented] || [self isBeingDismissed] ||
          [_navController isBeingDismissed] || [_navController isBeingPresented] ||
          [_mediaPicker isBeingDismissed]   || [_mediaPicker isBeingPresented]) {
        NSLog(@"Wating for view to load");
    }
    
    if(_navController && _navController.isViewLoaded && _navController.view.window) {
        [_navController dismissViewControllerAnimated:YES completion:^{
            [self presentViewController:viewController animated:NO completion:nil];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        }];
    } else if(_mediaPicker && _mediaPicker.isViewLoaded && _mediaPicker.view.window) {
        [_mediaPicker dismissViewControllerAnimated:YES completion:^{
            [self presentViewController:viewController animated:NO completion:nil];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        }];
    } else {
        [self presentViewController:viewController animated:YES completion:nil];
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_game != nil) {
        return [_game.playlist count];
    } else {
        return 0;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";

    PlaylistItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    PlaylistItem *selectedItem = ((PlaylistItem *)[_game.playlist objectAtIndex:indexPath.row]);
    
     
    if (cell == nil) {
        cell = [[PlaylistItemCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:nil
                                          playlistItem:selectedItem
                                                 voted:([_hasVotedForItem objectForKey:selectedItem.ID] != nil)
                                              position:indexPath.row];
        cell.delegate = self;
    }
    return cell;
}

- (void)setHeaderWithSongName:(NSString *)songName andArtistName:(NSString *)artistName
{
    _artistLabel.hidden = NO;
    _playbackProgressBar.hidden = NO;
    
    self.songTitle.text = songName;
    self.artistLabel.text = artistName;
    
}
#pragma mark - UITableViewDelegate

#pragma mark - MoviePickerDelegate

- (void)addMovie:(MPMediaItem *)movieItem {
    [_game uploadMusicWithMediaItem:movieItem video:YES];
}

- (void)addYoutubeVideo:(MediaItem *)youtubeItem
{
    NSLog(@"Added youtube video with url = %@", youtubeItem.url);
    [_game uploadYoutubeItem:youtubeItem];
    
}
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
    if([_hasVotedForItem objectForKey:ID]) {
        [_hasVotedForItem removeObjectForKey:ID];
    }
    else {
        [_hasVotedForItem setObject:@YES forKey:ID];
    }
}

- (void)cancelMusicAndUpdateAll:(PlaylistItem *)playlistItem {
    [playlistItem cancel];
    [self.game cancelMusic:playlistItem];
    [self.game sendCancelMusicPacket:playlistItem];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != alertView.cancelButtonIndex)
	{
        [self dismissViewControllerAnimated:YES completion:nil];
		[self.game quitGameWithReason:QuitReasonUserQuit];
	}
}

#pragma mark - playMusic____
- (IBAction)playMusic:(id)sender {
    _mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeMusic];
    
    _mediaPicker.delegate = self;
    _mediaPicker.allowsPickingMultipleItems = NO;
    //mediaPicker.prompt = @"Music";
    _mediaPicker.navigationItem.rightBarButtonItem.title = @"Cancel";
    _canLoadView = NO;
    [self presentViewController:_mediaPicker animated:YES completion:^{
        _canLoadView = YES;
    }];
}

- (IBAction)playMovie:(id)sender {
	MoviePickerViewController *moviePickerViewController = [[MoviePickerViewController alloc] initWithStyle:UITableViewStylePlain];
    _navController = [[UINavigationController alloc] initWithRootViewController:moviePickerViewController];
    _canLoadView = NO;
    [self presentViewController:_navController animated:YES completion:^{
        _canLoadView = YES;
    }];
	moviePickerViewController.delegate = self;
}
    
- (IBAction)skipMusic:(id)sender {
    [_game skipButtonPressed];
}

- (void)mediaPicker: (MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
    
    if (mediaItemCollection) {
        
        MPMediaItem *chosenItem = mediaItemCollection.items[0];
        
        [_game uploadMusicWithMediaItem:chosenItem video:NO];
    }
}

- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker
{
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)togglePartyMode:(UISwitch *)sender {
    NSLog(@"Toggling party mode");
    _game.partyMode = [sender isOn];
}

- (void)volumeChanged:(NSNotification *)notification
{
    float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    [self changeVolumeIcon:volume];
}

- (void)initialCheckVolume {
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    float volume = musicPlayer.volume;
    [self changeVolumeIcon:volume];
}

- (void)changeVolumeIcon: (float)volume{
    if (volume > .66) {
        [_volumeButton setBackgroundImage:[UIImage imageNamed:@"extrafullVolume-01.png"] forState:UIControlStateNormal];    }
    else if (volume <= .66 && volume > 0.33) {
        [_volumeButton setBackgroundImage:[UIImage imageNamed:@"fullVolume-01.png"] forState:UIControlStateNormal];    }
    else if (volume <= .33 && volume > 0.0) {
        [_volumeButton setBackgroundImage:[UIImage imageNamed:@"lowVolume-01.png"] forState:UIControlStateNormal];    }
    else {
        [_volumeButton setBackgroundImage:[UIImage imageNamed:@"muteVolume-01.png"] forState:UIControlStateNormal];    }
}



@end
