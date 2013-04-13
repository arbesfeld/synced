#import "GameViewController.h"
#import "PlaylistItemCell.h"
#import "ECSlidingViewController.h"
#import "MarqueeLabel.h"
#import <QuartzCore/QuartzCore.h>

const double epsilon = 0.02;

@interface GameViewController ()

@property (nonatomic, strong) MarqueeLabel * songTitle;

@end

@implementation GameViewController
{
    UIAlertView *_alertView;
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
    _currentPlaylistItem = [[PlaylistItem alloc] initPlaylistItemWithName:@"" andSubtitle:@"" andID:@"" andDate:nil andPlaylistItemType:PlaylistItemTypeNone];
    _currentPlaylistItem.loadProgress = 0.0;
    _voteAmount = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    self.view.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"bgGreyImg.png"]];
    //self.playlistTable.layer.cornerRadius = 12;
    self.playlistTable.layer.masksToBounds = YES;

    //self.playlistTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    

    self.artistLabel.hidden = YES;
    self.waitingLabel.hidden = NO;
    
    self.songTitle = [[MarqueeLabel alloc] initWithFrame:CGRectMake(20, 70, self.view.frame.size.width-40.0f, 20.0f) duration:6.0 andFadeLength:10.0f];
    self.songTitle.tag = 101;
    self.songTitle.numberOfLines = 1;
    self.songTitle.shadowOffset = CGSizeMake(0.0, -1.0);
    self.songTitle.textAlignment = NSTextAlignmentCenter;
    self.songTitle.textColor = [UIColor colorWithRed:0.234 green:0.234 blue:0.234 alpha:1.000];
    self.songTitle.backgroundColor = [UIColor clearColor];
    self.songTitle.font = [UIFont systemFontOfSize:17];
    self.songTitle.text = @"";
    [self.view addSubview:self.songTitle];

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

- (void)game:(Game *)game clientDidConnect:(Player *)player;
{
    [self.userTable reloadData];
    [self.playlistTable reloadData];
}

- (void)game:(Game *)game clientDidDisconnect:(Player *)player;
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

- (void)reloadPlaylistItem:(PlaylistItem *)playlistItem
{
    [self.playlistTable beginUpdates];
    int loc = [self.game indexForPlaylistItem:playlistItem];
    [self.playlistTable reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:loc inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    [self.playlistTable endUpdates];
}

- (void)addPlaylistItem:(PlaylistItem *)playlistItem
{
    [self.playlistTable beginUpdates];
    int loc = [self.game indexForPlaylistItem:playlistItem];
    //NSLog(@"inserting at loc %d", loc);
    [self.playlistTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:loc inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
        
    [self.playlistTable endUpdates];
}

- (void)removePlaylistItem:(PlaylistItem *)playlistItem animation:(UITableViewRowAnimation)animation
{
    [self.playlistTable beginUpdates];
    int loc = [self.game indexForPlaylistItem:playlistItem];
    // if it will be played but not at the top, don't show an animation
    if(animation == UITableViewRowAnimationTop && loc != 0) {
        [self.playlistTable deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:loc inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    } else {
        [self.playlistTable deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:loc inSection:0]] withRowAnimation:animation];
    }
    
    [self.game.playlist removeObject:playlistItem];
    [self.playlistTable endUpdates];
    
    //update the row labels of the songs
    for(int i = 0; i < self.game.playlist.count; i++) {
        PlaylistItemCell *cell = (PlaylistItemCell *)[self.playlistTable cellForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
        cell.positionLabel.text = [NSString stringWithFormat:@"%d.", i+1];
    }
}

- (void)audioPlayerFinishedPlaying
{
    _waitingLabel.hidden = NO;
    _artistLabel.hidden = YES;
    self.songTitle.text = @"";
}

- (void)game:(Game *)game setCurrentItem:(PlaylistItem *)playlistItem
{
    _currentPlaylistItem = playlistItem;
    if([_currentPlaylistItem.name isEqualToString:@""] && [_currentPlaylistItem.subtitle isEqualToString:@""] && [_currentPlaylistItem.ID isEqualToString:@""]) {
        return;
    }
    
    _waitingLabel.hidden = YES;
    [self setHeaderWithSongName:playlistItem.name andArtistName:playlistItem.subtitle];
}

- (void)game:(Game *)game setSkipSongCount:(int)skipSongCount
{
    self.skipSongLabel.text = [NSString stringWithFormat:@"%d/%d", skipSongCount, game.players.count];
}

- (void)gameSessionDidEnd:(Game *)server;
{
    
}

- (void)gameNoNetwork:(Game *)server;
{
}

- (PlaylistItem *)getCurrentPlaylistItem {
    return _currentPlaylistItem;
}

- (void)setPlaybackProgress:(double)f {
    self.playbackProgressBar.progress = f;
    if(f == 0.0) {
        self.playbackProgressBar.hidden = YES;
    } else {
        self.playbackProgressBar.hidden = NO;
    }
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
        if (_game != nil) {
            //return [_game.playlist count];
            //count the songs that are still valid (not cancelled)
            NSInteger len = [_game.playlist count];
            return len;
        } else {
            return 0;
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
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
            cell = [[PlaylistItemCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil playlistItem:selectedItem voteValue:[[_voteAmount objectForKey:selectedItem.ID] intValue] position:indexPath.row];
            cell.delegate = self;
        }
        return cell;
    }
}

- (void)setHeaderWithSongName:(NSString *)songName andArtistName:(NSString *)artistName
{

    _artistLabel.hidden = NO;
    _playbackProgressBar.hidden = NO;
    
    self.songTitle.text = songName;
    self.songTitle.font = [UIFont fontWithName:@"Century Gothic" size:18.0f];
    self.artistLabel.text = artistName;
    self.artistLabel.font = [UIFont fontWithName:@"Century Gothic" size:14.0f];
    self.artistLabel.textColor = [UIColor darkGrayColor];
    
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

- (void)cancelMusicAndUpdateAll:(PlaylistItem *)playlistItem {
    [playlistItem cancel];
    [self.game cancelMusic:playlistItem];
    // send a packet
    [self.game sendCancelMusicPacket:playlistItem];
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
    
- (IBAction)skipMusic:(id)sender {
    [_game skipButtonPressed];
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
