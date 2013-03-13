#import "HostViewController.h"
#import "MainViewController.h"
#import "GameViewController.h"
#import "MatchmakingClient.h"

@interface MainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, HostViewControllerDelegate,GameViewControllerDelegate, MatchmakingClientDelegate>

@property (weak, nonatomic) IBOutlet UIButton *hostGameButton;
@property (weak, nonatomic) IBOutlet UIButton *joinGameButton;

@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UILabel *waitLabel;
@property (strong, nonatomic) IBOutlet UILabel *sessionsLabel;


- (IBAction)hostGameAction:(id)sender;
- (IBAction)joinGameAction:(id)sender;
@end
