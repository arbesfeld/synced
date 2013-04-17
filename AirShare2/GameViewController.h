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
    PlaylistItem *_currentPlaylistItem;
    NSMutableDictionary *_voteAmount; // key is songID, value is vote amount
}
@property (nonatomic, weak) IBOutlet UILabel *skipSongLabel;
@property (nonatomic, weak) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *waitingLabel;
@property (nonatomic, weak) IBOutlet UIButton *exitButton;
@property (weak, nonatomic) IBOutlet UIButton *skipSongButton;
@property (nonatomic, weak) IBOutlet UITableView *userTable;
@property (nonatomic, weak) IBOutlet UITableView *playlistTable;
@property (nonatomic, weak) IBOutlet UIProgressView *playbackProgressBar;

@property (nonatomic, weak) id <GameViewControllerDelegate> delegate;
@property (nonatomic, strong) Game *game;

- (IBAction)exitAction:(id)sender;
- (IBAction)playMusic:(id)sender;
- (IBAction)skipMusic:(id)sender;
- (IBAction)playMovie:(id)sender;
- (IBAction)togglePartyMode:(UISwitch *)sender;

@end