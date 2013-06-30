#import "MainViewController.h"
#import "GameViewController.h"
#import "Game.h"
#import "MatchmakingClient.h"
#import <QuartzCore/QuartzCore.h>

@interface MainViewController ()

@end

@implementation MainViewController {
    BOOL tapped;
    
	MatchmakingClient *_matchmakingClient;
    QuitReason _quitReasonClient;
    
    MatchmakingServer *_matchmakingServer;
    QuitReason _quitReasonServer;
    CBCentralManager* _testBluetooth;
    NSString *_serverName;
    NSTimer *_tapTimer;
    
    double _verticalOffset;
    
    CGRect screenRect;
    CGFloat screenWidth, screenHeight;
    
    Reachability *internetReachable;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:self];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    tapped = NO;
    
    _matchmakingClient = [[MatchmakingClient alloc] init];
    _matchmakingClient.delegate = self;
    [_matchmakingClient startSearchingForServersWithSessionID:SESSION_ID];
    
    [self setupUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self testBluetooth];
    [self testInternetConnection];
}

- (void)didBecomeActive {
    NSLog(@"Did become active");
    [_matchmakingClient startSearchingForServersWithSessionID:SESSION_ID];
}


- (IBAction)backAction:(id)sender {
    [UIView animateWithDuration:0.6 animations:^() {
        [self.tableView setAlpha:0.0];
        [_internetLabel setAlpha:1.0];
        [_backButton setAlpha:0.0];
        [_hostGameButton setAlpha:1.0];
        [_joinGameButton setAlpha:1.0];
        [_sessionsLabel setAlpha:0.0];
        [_waitingView setAlpha:0.0];
    }];
    if(IS_PHONE) {
        [self performSelector:@selector(reloadMainScreen:) withObject:nil afterDelay:.4];
    }
}

- (IBAction)joinGameAction:(id)sender {
    [self testBluetooth];
    [self testInternetConnection];
    
    [_tapTimer invalidate];
    _tapTimer = nil;
    
    [self.tableView reloadData];
    
    if(IS_PHONE) {
        [UIView animateWithDuration:0.6 animations:^() {
            _joinGameButton.frame = CGRectMake(-320,272+_verticalOffset,320,54);
            _hostGameButton.frame = CGRectMake(320,195+_verticalOffset,320,54);
            _internetLabel.alpha = 1.0;
        }];
    }
    [self performSelector:@selector(releaseMainScreen:) withObject:nil afterDelay:.4];
}

- (IBAction)hostGameAction:(id)sender
{
    if(IS_PHONE) {
        [UIView animateWithDuration:0.6 animations:^() {
            _joinGameButton.frame = CGRectMake(-320,272+_verticalOffset,320,54);;
            _hostGameButton.frame = CGRectMake(320,195+_verticalOffset,320,54);
            _internetLabel.alpha = 1.0;
        }];
        [self performSelector:@selector(startGame:) withObject:nil afterDelay:.4];
    } else {
        [self startGame:nil];
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
    NSLog(@"Start game with server: %@ and name: %@", peerID, name);
    [self startGameWithBlock:^(Game *game) {
        [game startClientGameWithSession:session playerName:name server:peerID]; }];
}

- (void)startGameWithBlock:(void (^)(Game *))block
{
    tapped = NO;
    _waitingView.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    
    ECSlidingViewController *slidingViewController = [[ECSlidingViewController alloc] init];
    GameViewController *gameViewController = [storyboard instantiateViewControllerWithIdentifier:@"GameViewController"];
    slidingViewController.topViewController = gameViewController;
    slidingViewController.delegate = gameViewController;
    gameViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    slidingViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    slidingViewController.topViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    Game *game = [[Game alloc] init];
    gameViewController.game = game;
    gameViewController.delegate = self;
    game.delegate = gameViewController;
    
    [self presentViewController:slidingViewController animated:YES completion:nil];
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
                              message:NSLocalizedString(@"To use Synced, please enable WiFi or data in your device's Settings.", @"No network alert message")
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", @"Button: Cancel")
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
    _waitingView.hidden = YES;
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
    [self setupUI];
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
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.font = [UIFont fontWithName:@"Century Gothic" size:18.0f];
	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (tapped) {
        return;
    }
    tapped = YES;
    
    _waitingView.hidden = NO;

    _tapTimer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(tapTimerFired:) userInfo:nil repeats:NO];
    
    NSString *peerID = [_matchmakingClient peerIDForAvailableServerAtIndex:indexPath.row];
    [_matchmakingClient connectToServerWithPeerID:peerID];
}

- (void)tapTimerFired:(NSTimer *)timer {
    tapped = NO;
//    _waitingView.hidden = YES;
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
    NSLog(@"Setting up UI");
          
    _airshareLogo.hidden = YES;
    _hostGameButton.hidden = YES;
    _joinGameButton.hidden = YES;
    
    _quitReasonClient = QuitReasonConnectionDropped;
    
    screenRect = [[UIScreen mainScreen] bounds];
    screenWidth = screenRect.size.width;
    screenHeight = screenRect.size.height;
    
    if(!IS_PHONE) {
        _verticalOffset = -50.0f;
        _tableViewConstraint.constant = 2 * screenWidth/5;
        _tapToJoinConstraint.constant = screenWidth/3;
    }
    else if(IS_IPHONE_5) {
        _verticalOffset = 50.0f;
    } else {
        _verticalOffset = 20.0f;
    }
    
    [self.tableView setAlpha:0.0];
    [_hostGameButton setAlpha:1.0];
    [_joinGameButton setAlpha:1.0];
    [_sessionsLabel setAlpha:0.0];
    [_backButton setAlpha:0.0];
    
    _waitingView.hidden = YES;
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    NSString *gradientLocation = [[NSBundle mainBundle] pathForResource:@"gradient_transparent" ofType:@"png"];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"loading" withExtension:@"gif"];

    if(!IS_PHONE) {
        [self.background setImage:[UIImage imageNamed:@"BGIpad.png"]];
    } else if(IS_IPHONE_5) {
        [self.background setImage:[UIImage imageNamed:@"metalHolesIP5.png"]];
    } else {
        [self.background setImage:[UIImage imageNamed:@"metalHolesIP4.png"]];
    }
    
    self.view.BackgroundColor = [UIColor blackColor];
    self.tableView.layer.cornerRadius = 7;
    self.tableView.layer.masksToBounds = YES;
    
    self.sessionsLabel.font = [UIFont fontWithName:@"Century Gothic" size:22.0f];
    self.sessionsLabel.textColor = [UIColor whiteColor];
    
    self.internetLabel.font = [UIFont fontWithName:@"Century Gothic" size:16.0f];
    self.internetLabel.textColor = [UIColor lightGrayColor];

    _waitingView.image = [UIImage animatedImageWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
    _waitingView.hidden = YES;
    
    float width = 320;
    if(!IS_PHONE) {
        CGRect frame = [UIScreen mainScreen].applicationFrame;
        width = MAX(frame.size.height, frame.size.width);
    }
    
    _gradientLoadProgress = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:gradientLocation]];
    [_gradientLoadProgress setAlpha:1.0];
    _gradientLoadProgress.frame = CGRectMake(0,0,width,54);
    _gradientLoadProgressTwo = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:gradientLocation]];
    [_gradientLoadProgressTwo setAlpha:1.0];
    _gradientLoadProgressTwo.frame = CGRectMake(0,0,width,54);
    
    int start = IS_PHONE ? 320 : screenHeight;
    _joinGameButton = [[UIButton alloc] initWithFrame:CGRectMake(start,272+_verticalOffset, 320, 54)];
    [_joinGameButton addTarget:self action:@selector(joinGameAction:) forControlEvents:UIControlEventTouchUpInside];
    [_joinGameButton setTitle:@"Join" forState:UIControlStateNormal];
    _joinGameButton.titleLabel.font = [UIFont fontWithName:@"Century Gothic" size:22.0f];
    _joinGameButton.layer.shadowOffset = CGSizeMake(2, 2);
    _joinGameButton.layer.shadowColor = [[UIColor blackColor] CGColor];
    _joinGameButton.layer.shadowOpacity = .5f;
    _joinGameButton.layer.borderColor = [UIColor blackColor].CGColor;
    _joinGameButton.layer.borderWidth = 0.0f;
    _joinGameButton.hidden = true;
    _joinGameButton.layer.backgroundColor = [UIColor colorWithRed:255/255.0 green:70/225.0 blue:0/225.0 alpha:1].CGColor;
    [_joinGameButton addSubview:_gradientLoadProgress];
    [_joinGameButton bringSubviewToFront:_gradientLoadProgress];
    [self.view addSubview:_joinGameButton];

    
    _hostGameButton = [[UIButton alloc] initWithFrame:CGRectMake(-start,195+_verticalOffset, 320, 54)];
    [_hostGameButton addTarget:self action:@selector(hostGameAction:) forControlEvents:UIControlEventTouchUpInside];
    [_hostGameButton setTitle:@"Host" forState:UIControlStateNormal];
    _hostGameButton.titleLabel.font = [UIFont fontWithName:@"Century Gothic" size:22.0f];
    _hostGameButton.layer.shadowOffset = CGSizeMake(2, 2);
    _hostGameButton.layer.shadowColor = [[UIColor blackColor] CGColor];
    _hostGameButton.layer.shadowOpacity = .5f;
    _hostGameButton.layer.borderColor = [UIColor blackColor].CGColor;
    _hostGameButton.layer.borderWidth = 0.0f;
    _hostGameButton.layer.backgroundColor = [UIColor colorWithRed:255/255.0 green:150/225.0 blue:0/225.0 alpha:1].CGColor;
    _hostGameButton.hidden = true;
    [_hostGameButton addSubview:_gradientLoadProgressTwo];
    [_hostGameButton bringSubviewToFront:_gradientLoadProgressTwo];
    [self.view addSubview:_hostGameButton];

    
    if(!IS_PHONE) {
        _airshareLogo = [[UIImageView alloc] initWithFrame:CGRectMake(screenHeight/2 - 162, screenWidth/2 - 190,300, 300)];
        _airshareLogo.contentMode = UIViewContentModeScaleAspectFit;
    } else if(IS_IPHONE_5) {
        _airshareLogo = [[UIImageView alloc] initWithFrame:CGRectMake(-25, 190, 346, 130)];
        _airshareLogo.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        _airshareLogo = [[UIImageView alloc] initWithFrame:CGRectMake(-25, 145, 346, 130)];
        _airshareLogo.contentMode = UIViewContentModeScaleAspectFit;
    }
    _airshareLogo.image = [UIImage imageNamed:@"synced-01.png"];
    [self.view addSubview:_airshareLogo];
    
    
    [UIView animateWithDuration:.6 animations:^() {
        _airshareLogo.alpha = 1.0;
        _internetLabel.alpha = 1.0;
        if(!IS_PHONE) {
            _airshareLogo.frame = CGRectMake(screenHeight/2 - 162, 0, 300, 300);
        } else if(IS_IPHONE_5) {
           _airshareLogo.frame = CGRectMake(-25, 40, 346, 130);
        } else {
           _airshareLogo.frame = CGRectMake(-25, 40, 346, 130);
        }
    }];
    
    _airshareLogo.hidden = NO;
    _hostGameButton.hidden = NO;
    _joinGameButton.hidden = NO;
    //if(IS_PHONE) {
    [self performSelector:@selector(uiMainScreenDelay:) withObject:nil afterDelay:.3];
    //} else {
      //  _hostGameButton.hidden = NO;
        //_joinGameButton.hidden = NO;
    //}
    
}

- (void)uiMainScreenDelay:(id)sender {
    if(!IS_PHONE) {
        _hostGameButton.frame = CGRectMake(-screenHeight,screenWidth/2 + 2 * _verticalOffset, screenHeight, 54);
        _joinGameButton.frame = CGRectMake(screenHeight,screenWidth/2, screenHeight, 54);

    }
    else{
        _hostGameButton.frame = CGRectMake(-320,195+_verticalOffset, 320, 54);
        _joinGameButton.frame = CGRectMake(320,272+_verticalOffset, 320, 54);
    }
    _joinGameButton.hidden = false;
    _hostGameButton.hidden = false;
    [UIView animateWithDuration:0.6 animations:^() {
        _internetLabel.alpha = 1.0;
        if(!IS_PHONE) {
            _hostGameButton.frame = CGRectMake(0,screenWidth/2 + 2 * _verticalOffset, screenHeight, 54);
            _joinGameButton.frame = CGRectMake(0,screenWidth/2, screenHeight, 54);
            
        }
        else{
            _joinGameButton.frame = CGRectMake(0,272+_verticalOffset,320,54);
            _hostGameButton.frame = CGRectMake(0,195+_verticalOffset,320,54);
        }

    }];
}

- (void)testInternetConnection
{
    internetReachable = [Reachability reachabilityWithHostname:@"www.google.com"];
    internetReachable.reachableOnWWAN = YES;

    __weak typeof(self) weakSelf = self;
    // Internet is reachable
    internetReachable.reachableBlock = ^(Reachability*reach)
    {
    };
    
    // Internet is not reachable
    internetReachable.unreachableBlock = ^(Reachability*reach)
    {
        // Update the UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showNoNetworkAlert];
        });
    };
    
    [internetReachable startNotifier];
}

- (void)testBluetooth {
    _testBluetooth = [[CBCentralManager alloc] initWithDelegate:nil queue: nil];
    [_testBluetooth state];
}

- (void)reloadMainScreen:(id)sender {
    [UIView animateWithDuration:0.6 animations:^() {
        _internetLabel.alpha = 1.0;
        if(!IS_PHONE) {
            _hostGameButton.frame = CGRectMake(0,screenWidth/2 + 2 * _verticalOffset, screenHeight, 54);
            _joinGameButton.frame = CGRectMake(0,screenWidth/2, screenHeight, 54);
            
        }
        else{
        _joinGameButton.frame = CGRectMake(0,272+_verticalOffset,320,54);;
        _hostGameButton.frame = CGRectMake(0,195+_verticalOffset,320,54);
        }
    }];
}

- (void)releaseMainScreen:(id)sender {
    [UIView animateWithDuration:0.4 animations:^() {
        [self.tableView setAlpha:1.0];
        [_internetLabel setAlpha:0.0];
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
    
    [self serverStartGameWithSession:_matchmakingServer.session playerName:UIDevice.currentDevice.name clients:_matchmakingServer.connectedClients];
    _matchmakingServer = nil;
    _hostGameButton.alpha = 0.0;
    _joinGameButton.alpha = 0.0;
    _internetLabel.alpha = 0.0;
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
