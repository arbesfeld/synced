#import "MainViewController.h"
#import "GameViewController.h"
#import "Game.h"
#import "MatchmakingClient.h"
#import <QuartzCore/QuartzCore.h>

@interface MainViewController ()

@end

@implementation MainViewController

{
	MatchmakingClient *_matchmakingClient;
    QuitReason _quitReasonClient;
    
    MatchmakingServer *_matchmakingServer;
    QuitReason _quitReasonServer;
    
    NSString *_serverName;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    [self setupUI];
}

- (void)reload
{
    NSLog(@"Reload");
    _matchmakingClient = nil;
    _quitReasonClient = QuitReasonConnectionDropped;
    _matchmakingClient = [[MatchmakingClient alloc] init];
    _matchmakingClient.delegate = self;
    [_matchmakingClient startSearchingForServersWithSessionID:SESSION_ID];
    
    self.nameTextField.placeholder = _matchmakingClient.session.displayName;
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    [self reload];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // cancel was clicked
    if(buttonIndex == alertView.cancelButtonIndex)
        return;
    
    _serverName = [alertView textFieldAtIndex:0].text;
    [self hostGameAction:self];
}

- (IBAction)hostGameAction:(id)sender
{
    if(_serverName == nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Session Name?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [alert addButtonWithTitle:@"Ok"];
        [alert show];
    }
    
    // set up server
    
    if (_matchmakingServer == nil && _serverName.length != 0)
	{
		_matchmakingServer = [[MatchmakingServer alloc] init];
		_matchmakingServer.maxClients = 3;
        _matchmakingServer.delegate = self;
		[_matchmakingServer startAcceptingConnectionsForSessionID:SESSION_ID name:_serverName];
        
		//self.nameTextField.placeholder = _matchmakingServer.session.displayName;
		//[self.tableView reloadData];
	}
    
    // start server but wait until alertView is responded to
    if (_matchmakingServer != nil &&  _serverName.length != 0)//&& [_matchmakingServer connectedClientCount] > 0)
	{
		if ([_serverName length] == 0)
			_serverName = _matchmakingServer.session.displayName;
        
		//[_matchmakingServer stopAcceptingConnections];
        _matchmakingClient = nil;
		[self serverStartGameWithSession:_matchmakingServer.session playerName:_serverName clients:_matchmakingServer.connectedClients];
        _serverName = nil;
    }
}

- (void)serverDidEndSessionWithReason:(QuitReason)reason
{
	if (reason == QuitReasonNoNetwork)
	{
		[self showNoNetworkAlert];
	}
}

- (void)serverStartGameWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients
{
    [self startGameWithBlock:^(Game *game)
      {
          [game startServerGameWithSession:session playerName:name clients:clients];
      }];
    
}

- (void)startGameWithSession:(GKSession *)session playerName:(NSString *)name server:(NSString *)peerID
{
    NSLog(@"Start game with server: %@", peerID);
    [self startGameWithBlock:^(Game *game) {
        [game startClientGameWithSession:session playerName:name server:peerID]; }];
}

- (void)startGameWithBlock:(void (^)(Game *))block
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
	GameViewController *gameViewController = [storyboard instantiateViewControllerWithIdentifier:@"GameViewController"];
    [self presentViewController:gameViewController animated:YES completion:nil];
	gameViewController.delegate = self;
    
    Game *game = [[Game alloc] init];
    gameViewController.game = game;
    game.delegate = gameViewController;
    block(game);
}

- (void)serverDidDisconnectWithReason:(QuitReason)reason
{
	if (reason == QuitReasonNoNetwork)
	{
		[self showNoNetworkAlert];
	}
	else if (reason == QuitReasonConnectionDropped)
	{
        [self showDisconnectedAlert];
	}
}

- (void)showNoNetworkAlert
{
	UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"No Network", @"No network alert title")
                              message:NSLocalizedString(@"To use multiplayer, please enable Bluetooth or Wi-Fi in your device's Settings.", @"No network alert message")
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", @"Button: OK")
                              otherButtonTitles:nil];
    
	[alertView show];
}

- (void)showDisconnectedAlert
{
	UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Disconnected", @"Client disconnected alert title")
                              message:NSLocalizedString(@"You were disconnected from the game.", @"Client disconnected alert message")
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", @"Button: OK")
                              otherButtonTitles:nil];
    
	[alertView show];
}
     
#pragma mark - GameViewControllerDelegate
     
 - (void)gameViewController:(GameViewController *)controller didQuitWithReason:(QuitReason)reason
{
    [self dismissViewControllerAnimated:NO completion:^
     {
         if (reason == QuitReasonConnectionDropped)
         {
             [self showDisconnectedAlert];
         }
     }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (_matchmakingClient != nil)
		return [_matchmakingClient availableServerCount];
	else
		return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"CellIdentifier";
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
	NSString *peerID = [_matchmakingClient peerIDForAvailableServerAtIndex:indexPath.row];
	cell.textLabel.text = [_matchmakingClient displayNameForPeerID:peerID];
    
	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
	if (_matchmakingClient != nil)
	{
		self.waitLabel.text = @"Connect...";
        
		NSString *peerID = [_matchmakingClient peerIDForAvailableServerAtIndex:indexPath.row];
		[_matchmakingClient connectToServerWithPeerID:peerID];
	}
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}
#pragma mark - MatchmakingServerDelegate

- (void)matchmakingServer:(MatchmakingServer *)server clientDidConnect:(NSString *)peerID
{
	[self.tableView reloadData];
}

- (void)matchmakingServer:(MatchmakingServer *)server clientDidDisconnect:(NSString *)peerID
{
	[self.tableView reloadData];
}

- (void)matchmakingServerSessionDidEnd:(MatchmakingServer *)server
{
	_matchmakingServer.delegate = nil;
	_matchmakingServer = nil;
	[self.tableView reloadData];
	[self serverDidEndSessionWithReason:_quitReasonServer];
}

- (void)matchmakingServerNoNetwork:(MatchmakingServer *)session
{
	_quitReasonServer = QuitReasonNoNetwork;
}

#pragma mark - MatchmakingClientDelegate

- (void)matchmakingClient:(MatchmakingClient *)client serverBecameAvailable:(NSString *)peerID
{
	[self.tableView reloadData];
}

- (void)matchmakingClient:(MatchmakingClient *)client serverBecameUnavailable:(NSString *)peerID
{
	[self.tableView reloadData];
}

- (void)matchmakingClient:(MatchmakingClient *)client didConnectToServer:(NSString *)peerID
{
    NSLog(@"Connected to server! %@", peerID);
	NSString *name = [self.nameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([name length] == 0)
		name = _matchmakingClient.session.displayName;
    
	[self startGameWithSession:_matchmakingClient.session playerName:name server:peerID];
}

- (void)matchmakingClient:(MatchmakingClient *)client didDisconnectFromServer:(NSString *)peerID
{
	_matchmakingClient.delegate = nil;
	_matchmakingClient = nil;
	[self.tableView reloadData];
	[self serverDidDisconnectWithReason:_quitReasonClient];
    
    _matchmakingClient = [[MatchmakingClient alloc] init];
    _matchmakingClient.delegate = self;
    [_matchmakingClient startSearchingForServersWithSessionID:SESSION_ID];
    
    self.nameTextField.placeholder = _matchmakingClient.session.displayName;
    [self.tableView reloadData];
}

- (void)matchmakingClientNoNetwork:(MatchmakingClient *)client
{
	_quitReasonClient = QuitReasonNoNetwork;
}

-(void)setupUI
{
    self.view.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"bgGreyImg.png"]];
    [[UILabel appearance] setFont:[UIFont fontWithName:@"Century Gothic Std" size:17.0]];
    [[UILabel appearance] setTextColor:[UIColor colorWithHue:0.0 saturation:0.0 brightness:.2 alpha:1.0]];
    [[UIButton appearance] setFont:[UIFont fontWithName:@"Century Gothic Std" size:17.0]];
    [[UIButton appearance] setTitleColor:[UIColor colorWithHue:0.0 saturation:0.0 brightness:0.2 alpha:1.0] forState:UIControlStateNormal];
    [self.sessionsLabel setFont:[UIFont systemFontOfSize:24]];
    [self.sessionsLabel setTextAlignment:NSTextAlignmentCenter];
    self.tableView.layer.cornerRadius = 7;
    self.tableView.layer.masksToBounds = YES;
}


#pragma mark - Delloc

- (void)dealloc
{
#ifdef DEBUG
	NSLog(@"dealloc %@", self);
#endif
    [MainViewController class];
}

@end
