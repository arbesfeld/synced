#import "MainViewController.h"
#import "GameViewController.h"
#import "MatchmakingClient.h"
#import "MatchmakingServer.h"
#import "UIImage+animatedGIF.h"
#import "EGORefreshTableHeaderView.h"
#import "ECSlidingViewController.h"
#import "Reachability.h"

#import <CoreBluetooth/CoreBluetooth.h>

@interface MainViewController : UIViewController <EGORefreshTableHeaderDelegate, UITableViewDataSource, UITableViewDelegate, GameViewControllerDelegate, MatchmakingClientDelegate, MatchmakingServerDelegate>

@property (strong, nonatomic) IBOutlet UILabel *internetLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tapToJoinConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableViewConstraint;
@property (strong, nonatomic) IBOutlet UIImageView *background;
@property (strong, nonatomic) IBOutlet UIButton *hostGameButton;
@property (strong, nonatomic) IBOutlet UIButton *joinGameButton;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIImageView *waitingView;
@property (strong, nonatomic) IBOutlet UILabel *sessionsLabel;
@property (nonatomic, strong) UIView *gradientLoadProgress, *gradientLoadProgressTwo;
@property (nonatomic, strong) UIImageView *airshareLogo;


- (IBAction)backAction:(id)sender;
- (IBAction)joinGameAction:(id)sender;
- (IBAction)hostGameAction:(id)sender;



@end
