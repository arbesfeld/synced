#import "GameViewController.h"

@interface GameViewController ()


@end

@implementation GameViewController

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Actions

- (IBAction)exitAction:(id)sender
{
    [self.game endSession];
	[self.game quitGameWithReason:QuitReasonUserQuit];
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

- (void)gameServer:(Game *)server clientDidConnect:(NSString *)peerID;
{
    [self.tableView reloadData];
}

- (void)gameServer:(Game *)server clientDidDisconnect:(NSString *)peerID;
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


@end
