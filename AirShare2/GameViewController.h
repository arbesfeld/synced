#import "Game.h"
#import "MatchmakingClient.h"
#import "MatchmakingServer.h"
#import "PlaylistItem.h"
#import "PlaylistItemCell.h"
#import "MoviePickerViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@class GameViewController;

@protocol GameViewControllerDelegate <NSObject>

- (void)gameViewController:(GameViewController *)controller didQuitWithReason:(QuitReason)reason;

@end

@interface GameViewController : UIViewController <UIAlertViewDelegate, UIApplicationDelegate, UITableViewDataSource, UITableViewDelegate, MPMediaPickerControllerDelegate, GameDelegate, PlaylistItemDelegate, MoviePickerDelegate> {
    NSMutableDictionary *_voteAmount; // key is songID, value is vote amount
    BOOL _canLoadView; // for when animations are occuring
}

@property (nonatomic, weak) IBOutlet UILabel *skipSongLabel, *artistLabel, *waitingLabel;
@property (nonatomic, weak) IBOutlet UIButton *exitButton, *skipSongButton;
@property (nonatomic, weak) IBOutlet UITableView *userTable, *playlistTable;
@property (nonatomic, weak) IBOutlet UIProgressView *playbackProgressBar;
@property (nonatomic, strong) UINavigationController *navController;
@property (nonatomic, strong) MPMediaPickerController *mediaPicker;
@property (nonatomic, weak) id <GameViewControllerDelegate> delegate;
@property (nonatomic, strong) Game *game;

- (IBAction)exitAction:(id)sender;
- (IBAction)playMusic:(id)sender;
- (IBAction)skipMusic:(id)sender;
- (IBAction)playMovie:(id)sender;
- (IBAction)togglePartyMode:(UISwitch *)sender;

@end