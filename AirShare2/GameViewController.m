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
    
    _hasVotedForItem = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    self.view.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"bgGreyImg.png"]];
    //self.playlistTable.layer.cornerRadius = 12;
    self.playlistTable.layer.masksToBounds = YES;

    //self.playlistTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (screenSize.height > 480.0f) {
            /*Do iPhone 5 stuff here.*/
        } else {
            [self.background setImage:[UIImage imageNamed:@"frostedBGip4.png"]];
            /*Do iPhone Classic stuff here.*/
        }
    } else {
        [self.background setImage:[UIImage imageNamed:@"BGFrostedIpad.png"]];
    }
    
    _itemNumber = 0;
    
    [self isWaiting:YES];
    
    [self.skipSongButton setHitTestEdgeInsets:UIEdgeInsetsMake(-10, -10, -10, -10)];
    
    self.playingLabel.font = [UIFont fontWithName:@"Century Gothic" size:11.0f];
    self.playingLabel.textColor = [UIColor lightGrayColor];
    
    self.partyModeLabel.hidden = true;
    self.partyModeLabel.font = [UIFont fontWithName:@"Century Gothic" size:11.0f];
    self.partyModeLabel.textColor = [UIColor lightGrayColor];
    
    self.songTitle.shadowOffset = CGSizeMake(0.0, -1.0);
    self.songTitle.textColor = [UIColor whiteColor];
    self.songTitle.backgroundColor = [UIColor clearColor];
    self.songTitle.font = [UIFont fontWithName:@"Century Gothic" size:16.0f];
    
    self.artistLabel.font = [UIFont fontWithName:@"Century Gothic" size:12.0f];
    self.artistLabel.textColor = [UIColor lightGrayColor];
    
    self.skipsLabel.font = [UIFont fontWithName:@"Century Gothic" size:11.0f];
    self.skipsLabel.textColor = [UIColor lightGrayColor];
    
    self.skipSongLabel.font = [UIFont fontWithName:@"Century Gothic" size:14.0f];
    self.skipSongLabel.textColor = [UIColor whiteColor];
    
    self.timeLabel.font = [UIFont fontWithName:@"Century Gothic" size:14.0f];
    self.timeLabel.textColor = [UIColor whiteColor];
    
    self.playlistTable.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    self.playbackProgressBar.progressTintColor = [UIColor colorWithRed:255/255.0 green:150/225.0 blue:0/225.0 alpha:1];
    self.playbackProgressBar.trackTintColor = [UIColor lightGrayColor];
    
    for (id current in self.volumeBar.subviews) {
        if ([current isKindOfClass:[UISlider class]]) {
            UISlider *volumeSlider = (UISlider *)current;
            volumeSlider.minimumTrackTintColor = [UIColor colorWithRed:255/255.0 green:70/225.0 blue:0/225.0 alpha:1];
            volumeSlider.maximumTrackTintColor = [UIColor lightGrayColor];
        }
    }
    
    _eyeButton.showsTouchWhenHighlighted = YES;
    _skipSongButton.showsTouchWhenHighlighted = YES;
    
    [self initialCheckVolume];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    
}
    
- (void)isWaiting:(BOOL)isWaiting
{
    self.playingLabel.hidden = isWaiting;
    self.songTitle.hidden = isWaiting;
    self.artistLabel.hidden = isWaiting;
    self.skipSongButton.hidden = isWaiting;
    self.skipSongLabel.hidden = isWaiting;
    self.timeLabel.hidden = isWaiting;
    self.playbackProgressBar.hidden = isWaiting;
    self.skipsLabel.hidden = isWaiting;
    self.partyModeLabel.hidden = isWaiting;
    self.partyButton.hidden = isWaiting;
    
    if(isWaiting) {
        // eye button only appears when video plays
        self.eyeButton.hidden = YES;
    }
    if(!isWaiting) {
        // a song is playing, definitely hide this message
        self.tapToAdd.hidden = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        _menuViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
        self.slidingViewController.underLeftViewController = _menuViewController;
    }
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    [self.slidingViewController setAnchorRightRevealAmount:180.0f];
    
    _menuViewController.game = _game;
    [_menuViewController.usersTable reloadData];
    
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
        [self.playlistTable beginUpdates];
        for(int i = 0; i < _game.playlist.count; i++) {
            for(int j = 0; j < newPlaylist.count; j++) {
                if (newPlaylist[j] == _game.playlist[i]) {
                    // row moved from i to j
                    if (i != j) {
                    [self.playlistTable moveRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]
                                               toIndexPath:[NSIndexPath indexPathForRow:j inSection:0]];
                    
                    } else {
                    [self.playlistTable reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                    }
                }
            }
        }
        [self.playlistTable endUpdates];
    }
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
    int count = (int) (_game.players.count / 2.0 - skipItemCount + 1);
    self.skipSongLabel.text = [NSString stringWithFormat:@"%d", count];
    if(count == 1) {
        self.skipsLabel.text = @"Skip Needed";
    } else {
        self.skipsLabel.text = @"Skips Needed";
    }
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
//    while([_navController isBeingDismissed] || [_navController isBeingPresented] ||
//          [_mediaPicker isBeingDismissed]   || [_mediaPicker isBeingPresented]) {
//        NSLog(@"Wating for view to load: navController: %@, %@, mediaPicker: %@, %@",
//              [_navController isBeingPresented] ? @"YES": @"NO",
//              [_navController isBeingDismissed] ? @"YES": @"NO",
//              [_mediaPicker isBeingPresented] ? @"YES": @"NO",
//              [_mediaPicker isBeingDismissed] ? @"YES": @"NO");
//    }
    
    if(_navController && _navController.isViewLoaded && _navController.view.window) {
        [_navController dismissViewControllerAnimated:YES completion:^{
            [self presentViewController:viewController animated:NO completion:nil];
        }];
    } else if(_mediaPicker && _mediaPicker.isViewLoaded && _mediaPicker.view.window) {
        [_mediaPicker dismissViewControllerAnimated:YES completion:^{
            [self presentViewController:viewController animated:NO completion:nil];
        }];
    } else {
        [self presentViewController:viewController animated:YES completion:nil];
    }
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    _displayedViewController = viewController;
    self.eyeButton.hidden = NO;
}

- (void)flashScreen
{
    const NSArray *colorTable = [[NSArray alloc] initWithObjects: [UIColor whiteColor] ,[UIColor greenColor] ,[UIColor yellowColor], [UIColor redColor], [UIColor blueColor], nil];
    //NSLog(@"BEAT!!");
    int rndIndex = arc4random()%[colorTable count];
    
    UIView *screenFlash = [[UIView alloc] initWithFrame:self.view.bounds];
    [screenFlash setBackgroundColor:[colorTable objectAtIndex:rndIndex]];

    [UIView animateWithDuration:0.6 animations:^() {
        screenFlash.alpha = 0.0;
    }];
    screenFlash.userInteractionEnabled = NO;
    [self.view addSubview:screenFlash];
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            [device lockForConfiguration:nil];
            
            [device setTorchModeOnWithLevel:0.1 error:NULL];
            
            // turn on
            [device setTorchMode:AVCaptureTorchModeOn];
            [device setFlashMode:AVCaptureFlashModeOn];
            
            // wait
            [self performSelector:@selector(turnOff:) withObject:device afterDelay:0.1];
        }
    }
    
}

- (void)turnOff:(AVCaptureDevice *)device
{
    // turn off
    [device setTorchMode:AVCaptureTorchModeOff];
    [device setFlashMode:AVCaptureFlashModeOff];
    
    [device unlockForConfiguration];
}

- (IBAction)eyeAction:(id)sender {
    [self presentViewController:_displayedViewController animated:YES completion:nil];
}

- (IBAction)partyAction:(id)sender {
    NSLog(@"Toggling party mode");
    _game.partyMode = [sender isOn];
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

- (void)voteForItem:(PlaylistItem *)playlistItem withValue:(int)value upvote:(BOOL)upvote {
    // value is a int that represents the weight of the vote
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
        [self.game updateServerStats:7];
        [_hasVotedForItem removeObjectForKey:ID];
    }
    else {
        [self.game updateServerStats:6];
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
    _tapToAdd.hidden = YES;
    _mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeMusic];
    
    _mediaPicker.delegate = self;
    _mediaPicker.allowsPickingMultipleItems = NO;
    //mediaPicker.prompt = @"Music";
    _mediaPicker.navigationItem.rightBarButtonItem.title = @"Cancel";
    [self presentViewController:_mediaPicker animated:YES completion:nil];
}

- (IBAction)playMovie:(id)sender {
    _tapToAdd.hidden = YES;
	MoviePickerViewController *moviePickerViewController = [[MoviePickerViewController alloc] initWithStyle:UITableViewStylePlain];
    _navController = [[UINavigationController alloc] initWithRootViewController:moviePickerViewController];
    
    [self presentViewController:_navController animated:YES completion:nil];
	moviePickerViewController.delegate = self;
}

    
- (IBAction)skipMusic:(id)sender {
    [_game skipButtonPressed];
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
    
    if (mediaItemCollection) {
        
        for(MPMediaItem *chosenItem in mediaItemCollection.items)
        {
            [_game uploadMusicWithMediaItem:chosenItem video:NO];
        }
    }
}

- (void) mediaPickerDidCancel:(MPMediaPickerController *) mediaPicker
{
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Volume Control

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
        _volumeImage.image = [UIImage imageNamed:@"extrafullVolume-01.png"];
    } else if (volume <= .66 && volume > 0.33) {
        _volumeImage.image = [UIImage imageNamed:@"fullVolume-01.png"];
    } else if (volume <= .33 && volume > 0.0) {
        _volumeImage.image = [UIImage imageNamed:@"lowVolume-01.png"];
    } else {
        _volumeImage.image = [UIImage imageNamed:@"muteVolume-01.png"];
    }
}

#pragma mark - ECSlidingViewControllerDelegate

- (void)hasSwipedLeft
{
    [UIView animateWithDuration:.6 animations:^() {
    _swipeToReveal.alpha = 0.0;
    }];
}


@end
