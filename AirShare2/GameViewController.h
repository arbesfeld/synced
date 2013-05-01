#import "Game.h"
#import "MatchmakingClient.h"
#import "MatchmakingServer.h"
#import "PlaylistItem.h"
#import "PlaylistItemCell.h"
#import "MoviePickerViewController.h"
#import "UIButton+Extensions.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"

#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>

@class GameViewController;

@protocol GameViewControllerDelegate <NSObject>

- (void)gameViewController:(GameViewController *)controller didQuitWithReason:(QuitReason)reason;

@end

@interface GameViewController : UIViewController <UIAlertViewDelegate, UIApplicationDelegate, UITableViewDataSource, UITableViewDelegate, MPMediaPickerControllerDelegate, GameDelegate, PlaylistItemDelegate, MoviePickerDelegate> {
    MenuViewController *_menuViewController;
    UIViewController *_displayedViewController;
    NSMutableDictionary *_hasVotedForItem; // key is songID, value is whethere they have upvoted it
}

@property (strong, nonatomic) IBOutlet UIImageView *tapToAdd;
@property (weak, nonatomic) IBOutlet UIButton *eyeButton;
@property (strong, nonatomic) IBOutlet UISwitch *partySwitch;
@property (strong, nonatomic) IBOutlet UILabel *partyModeLabel;
@property (strong, nonatomic) IBOutlet UIImageView *volumeImage;
@property (strong, nonatomic) IBOutlet UILabel *skipsLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UILabel *skipSongLabel, *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *playingLabel;
@property (weak, nonatomic) IBOutlet UIView *gradientView;
@property (nonatomic, weak) IBOutlet UIButton *exitButton, *skipSongButton;
@property (nonatomic, weak) IBOutlet UITableView *playlistTable;
@property (nonatomic, weak) IBOutlet UIProgressView *playbackProgressBar;
@property (nonatomic, weak) IBOutlet UILabel * songTitle;

@property (nonatomic, strong) UINavigationController *navController;
@property (nonatomic, strong) MPMediaPickerController *mediaPicker;
@property (nonatomic, strong) UIWebView *youtube;

@property (nonatomic, weak) id <GameViewControllerDelegate> delegate;
@property (nonatomic, strong) Game *game;

- (IBAction)exitAction:(id)sender;
- (IBAction)playMusic:(id)sender;
- (IBAction)skipMusic:(id)sender;
- (IBAction)playMovie:(id)sender;
- (IBAction)eyeAction:(id)sender;

- (IBAction)togglePartyMode:(UISwitch *)sender;


@end