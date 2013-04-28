#import "MainViewController.h"
#import "GameViewController.h"
#import "Game.h"
#import "MatchmakingClient.h"
#import <QuartzCore/QuartzCore.h>

@interface MainViewController ()

@end

@implementation MainViewController {
    int tapCount, tappedRow;
    NSTimer *tapTimer;
    
	MatchmakingClient *_matchmakingClient;
    QuitReason _quitReasonClient;
    
    MatchmakingServer *_matchmakingServer;
    QuitReason _quitReasonServer;
    
    NSString *_serverName;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    _quitReasonClient = QuitReasonConnectionDropped;
    [self setupUI];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    [self.tableView setAlpha:0.0];
    [_hostGameButton setAlpha:1.0];
    [_joinGameButton setAlpha:1.0];
    [_sessionsLabel setAlpha:0.0];
    [_backButton setAlpha:0.0];

    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

- (void)reload
{
    _matchmakingClient = [[MatchmakingClient alloc] init];
    _matchmakingClient.delegate = self;
    [_matchmakingClient startSearchingForServersWithSessionID:SESSION_ID];
    
    tapCount = 0;
    [self.tableView reloadData];
    
    [self.tableView setAlpha:0.0];
    [_hostGameButton setAlpha:1.0];
    [_joinGameButton setAlpha:1.0];
    [_backButton setAlpha:0.0];
    [_sessionsLabel setAlpha:0.0];


}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    _waitingView.hidden = YES;
    [self reload];
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
    if([_serverName isEqualToString:@""]) {
        _serverName = nil;
    }
    [self hostGameAction:self];
}

- (IBAction)backAction:(id)sender {
    [UIView animateWithDuration:0.6 animations:^() {
        [self.tableView setAlpha:0.0];
        [_backButton setAlpha:0.0];
        [_hostGameButton setAlpha:1.0];
        [_joinGameButton setAlpha:1.0];
        [_sessionsLabel setAlpha:0.0];
        [_waitingView setAlpha:0.0];
    }];
    [self performSelector:@selector(reloadMainScreen:) withObject:nil afterDelay:.4];


    
}

- (IBAction)joinGameAction:(id)sender {
    [self.tableView reloadData];
    [UIView animateWithDuration:0.6 animations:^() {
        _joinGameButton.frame = CGRectMake(-320,272,320,54);;
        _hostGameButton.frame = CGRectMake(320,195,320,54);
    }];
    [self performSelector:@selector(releaseMainScreen:) withObject:nil afterDelay:.4];
    
}

- (IBAction)hostGameAction:(id)sender
{
    [UIView animateWithDuration:0.6 animations:^() {
        _joinGameButton.frame = CGRectMake(-320,272,320,54);;
        _hostGameButton.frame = CGRectMake(320,195,320,54);
    }];
    [self performSelector:@selector(startGame:) withObject:nil afterDelay:.4];

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
    NSLog(@"Start game with server: %@ and name: %@", peerID, name);
    [self startGameWithBlock:^(Game *game) {
        [game startClientGameWithSession:session playerName:name server:peerID]; }];
}

- (void)startGameWithBlock:(void (^)(Game *))block
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
	GameViewController *gameViewController = [storyboard instantiateViewControllerWithIdentifier:@"GameViewController"];
    gameViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:gameViewController
                                              animated:YES
                                           completion:nil];
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
                              message:NSLocalizedString(@"You were disconnected from the session.", @"Client disconnected alert message")
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", @"Button: OK")
                              otherButtonTitles:nil];
    
	[alertView show];
}
     
#pragma mark - GameViewControllerDelegate
     
 - (void)gameViewController:(GameViewController *)controller didQuitWithReason:(QuitReason)reason
{
    [self dismissViewControllerAnimated:YES completion:^
     {
         if (reason == QuitReasonConnectionDropped)
         {
             [self showDisconnectedAlert];
             _waitingView.hidden = YES;
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
    cell.textLabel.font = [UIFont fontWithName:@"Century Gothic" size:18.0f];
	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
	if (_matchmakingClient != nil)
	{
        _waitingView.hidden = NO;
        
        if(tapCount == 1 && tapTimer != nil && tappedRow == indexPath.row){
            //double tap - Put your double tap code here
            [tapTimer invalidate];
            _waitingView.hidden = YES;
            tapTimer = nil;
        }
        else if(tapCount == 0){
            //This is the first tap. If there is no tap till tapTimer is fired, it is a single tap
            tapCount = tapCount + 1;
            tappedRow = indexPath.row;
            tapTimer = [NSTimer timerWithTimeInterval:2.0 target:self selector:@selector(tapTimerFired:) userInfo:nil repeats:NO];
        }
        else if(tappedRow != indexPath.row){
            //tap on new row
            tapCount = 0;
            if(tapTimer != nil){
                [tapTimer invalidate];
                tapTimer = nil;
            }
        }
        
		NSString *peerID = [_matchmakingClient peerIDForAvailableServerAtIndex:indexPath.row];
		[_matchmakingClient connectToServerWithPeerID:peerID];
	}
}

- (void)tapTimerFired:(NSTimer *)aTimer{
    //timer fired, there was a single tap on indexPath.row = tappedRow
    if(tapTimer != nil){
    	tapCount = 0;
    	tappedRow = -1;
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
	NSString *name = UIDevice.currentDevice.name;
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
    
    [self.tableView reloadData];
}

- (void)matchmakingClientNoNetwork:(MatchmakingClient *)client
{
	_quitReasonClient = QuitReasonNoNetwork;
}

-(void)setupUI
{
    self.view.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"bgGreyImg.png"]];
    self.tableView.layer.cornerRadius = 7;
    self.tableView.layer.masksToBounds = YES;
    
    self.sessionsLabel.font = [UIFont fontWithName:@"Century Gothic" size:20.0f];
    [_hostGameButton setTitle:@"Host" forState:UIControlStateNormal];
    _hostGameButton.titleLabel.font = [UIFont fontWithName:@"Century Gothic" size:20.0f];
    [_joinGameButton setTitle:@"Join" forState:UIControlStateNormal];
    _joinGameButton.titleLabel.font = [UIFont fontWithName:@"Century Gothic" size:20.0f];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"loading" withExtension:@"gif"];
    _waitingView.image = [UIImage animatedImageWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
    _waitingView.hidden = YES;
    
    _joinGameButton.frame = CGRectMake(320,272, 320, 54);
    _joinGameButton.layer.shadowOffset = CGSizeMake(2, 2);
    _joinGameButton.layer.shadowColor = [[UIColor blackColor] CGColor];
    _joinGameButton.layer.shadowOpacity = .5f;
    _joinGameButton.layer.borderColor = [UIColor grayColor].CGColor;
    _joinGameButton.layer.borderWidth = 1.0f;


    _joinGameButton.layer.backgroundColor = [UIColor colorWithRed:255/255.0 green:70/225.0 blue:0/225.0 alpha:.6].CGColor;
    
    NSString *gradientLocation = [[NSBundle mainBundle] pathForResource:@"gradient_transparent" ofType:@"png"];
    _gradientLoadProgress = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:gradientLocation]];
    [_joinGameButton addSubview:_gradientLoadProgress];
    [_gradientLoadProgress setAlpha:.25];
    _gradientLoadProgress.frame = CGRectMake(0,0,320,54);;

    _hostGameButton.frame = CGRectMake(-320,195, 320, 54);
    _hostGameButton.layer.shadowOffset = CGSizeMake(2, 2);
    _hostGameButton.layer.shadowColor = [[UIColor blackColor] CGColor];
    _hostGameButton.layer.shadowOpacity = .5f;
    _hostGameButton.layer.borderColor = [UIColor grayColor].CGColor;
    _hostGameButton.layer.borderWidth = 1.0f;
    _hostGameButton.layer.backgroundColor = [UIColor colorWithRed:255/255.0 green:150/225.0 blue:0/225.0 alpha:.6].CGColor;
    
       _gradientLoadProgressTwo = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:gradientLocation]];
    [_hostGameButton addSubview:_gradientLoadProgressTwo];
    [_gradientLoadProgressTwo setAlpha:.25];
    _gradientLoadProgressTwo.frame = CGRectMake(0,0,320,54);;

    [UIView animateWithDuration:1 animations:^() {
        _joinGameButton.frame = CGRectMake(0,77,320,54);;
        _hostGameButton.frame = CGRectMake(0,0,320,54);
    }];
    
}

- (void)reloadMainScreen:(id)sender {
    [UIView animateWithDuration:0.6 animations:^() {
    _joinGameButton.frame = CGRectMake(0,272,320,54);;
    _hostGameButton.frame = CGRectMake(0,195,320,54);
    }];
}
- (void)releaseMainScreen:(id)sender {
    [UIView animateWithDuration:0.4 animations:^() {
        [self.tableView setAlpha:1.0];
        [_backButton setAlpha:1.0];
        [_hostGameButton setAlpha:0.0];
        [_joinGameButton setAlpha:0.0];
        [_sessionsLabel setAlpha:1.0];
        [_waitingView setAlpha:1.0];
    }];
}
- (void)startGame:(id)sender {
    _matchmakingServer = [[MatchmakingServer alloc] init];
    _matchmakingServer.maxClients = 3;
    _matchmakingServer.delegate = self;
    [_matchmakingServer startAcceptingConnectionsForSessionID:SESSION_ID name:UIDevice.currentDevice.name];
    //[_matchmakingServer stopAcceptingConnections];
    _matchmakingClient = nil;
    [self serverStartGameWithSession:_matchmakingServer.session playerName:UIDevice.currentDevice.name clients:_matchmakingServer.connectedClients];
    _matchmakingServer = nil;
    _hostGameButton.alpha = 0.0;
    _joinGameButton.alpha = 0.0;
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
