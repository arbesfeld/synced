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

#pragma mark - MatchmakingServerDelegate

- (void)matchmakingServer:(MatchmakingServer *)server clientDidConnect:(NSString *)peerID
{
	//[self.tableView reloadData];
}

- (void)matchmakingServer:(MatchmakingServer *)server clientDidDisconnect:(NSString *)peerID
{
	//[self.tableView reloadData];
}

- (void)matchmakingServerSessionDidEnd:(MatchmakingServer *)server
{
	//_matchmakingServer.delegate = nil;
	//_matchmakingServer = nil;
	//[self.tableView reloadData];
	//[self serverDidEndSessionWithReason:_quitReasonServer];
}

- (void)matchmakingServerNoNetwork:(MatchmakingServer *)session
{
	//_quitReasonServer = QuitReasonNoNetwork;
}


@end
