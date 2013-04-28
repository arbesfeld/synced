#import "MainViewController.h"
#import "GameViewController.h"
#import "MatchmakingClient.h"
#import "MatchmakingServer.h"
#import "UIImage+animatedGIF.h"
#import "EGORefreshTableHeaderView.h"

@interface MainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, GameViewControllerDelegate, MatchmakingClientDelegate, MatchmakingServerDelegate>

@property (strong, nonatomic) IBOutlet UIButton *hostGameButton;
@property (strong, nonatomic) IBOutlet UIButton *joinGameButton;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIImageView *waitingView;
@property (strong, nonatomic) IBOutlet UILabel *sessionsLabel;
@property (nonatomic, strong) UIView *gradientLoadProgress;
@property (nonatomic, strong) UIView *gradientLoadProgressTwo;


- (IBAction)backAction:(id)sender;
- (IBAction)joinGameAction:(id)sender;
- (IBAction)hostGameAction:(id)sender;



@end
