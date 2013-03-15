#import "Game.h"
#import "MatchmakingClient.h"
#import "MatchmakingServer.h"
@class GameViewController;

@protocol GameViewControllerDelegate <NSObject>

- (void)gameViewController:(GameViewController *)controller didQuitWithReason:(QuitReason)reason;

@end

@interface GameViewController : UIViewController <UIAlertViewDelegate, GameDelegate, MatchmakingClientDelegate, MatchmakingServerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *centerLabel;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;
@property (nonatomic, weak) id <GameViewControllerDelegate> delegate;
@property (nonatomic, strong) Game *game;

- (IBAction)exitAction:(id)sender;

@end