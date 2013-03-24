#import "GameViewController.h"

@interface GameViewController ()


@end

@implementation GameViewController
{
    UIAlertView *_alertView;
}
@synthesize delegate = _delegate;
@synthesize game = _game;

@synthesize centerLabel = _centerLabel;

- (void)dealloc
{
#ifdef DEBUG
	NSLog(@"dealloc %@", self);
#endif
}

- (void)viewDidLoad
{
	[super viewDidLoad];
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
	self.centerLabel.text = NSLocalizedString(@"Waiting for game to start...", @"Status text: waiting for server");
}
- (void)gameWaitingForClientsReady:(Game *)game
{
	self.centerLabel.text = NSLocalizedString(@"Waiting for other players...", @"Status text: waiting for clients");
}

- (void)gameServer:(Game *)server clientDidConnect:(Player *)player;
{
    [self.tableView reloadData];
}

- (void)gameServer:(Game *)server clientDidDisconnect:(Player *)player;
{
    [self.tableView reloadData];
}

- (void)reloadTable
{
    [self.tableView reloadData];
}

- (void)gameServerSessionDidEnd:(Game *)server;
{
    
}

- (void)gameServerNoNetwork:(Game *)server;
{
    
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (_game != nil)
		return [_game.players count];
	else
		return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"CellIdentifier";
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
		cell = [[UITableViewCell alloc] init];
    
	NSString *peerID = [[_game.players allKeys] objectAtIndex:indexPath.row];
	cell.textLabel.text = [_game displayNameForPeerID:peerID];
    
	return cell;
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
    
    NSLog(@"didPickMediaItems:");
    if (mediaItemCollection) {
        
        MPMediaItem *chosenItem = mediaItemCollection.items[0];
        
        NSURL *songURL = [chosenItem valueForProperty: MPMediaItemPropertyAssetURL];
        NSLog(@"url = %@", songURL);
        [_game uploadMusicWithMediaItem:chosenItem];
    }
}

- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker
{
    NSLog(@"mediaPickerDidCancel");
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}
@end
