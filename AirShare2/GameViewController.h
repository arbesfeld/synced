#import "Game.h"
#import "MatchmakingClient.h"
#import "MatchmakingServer.h"
#import "PlaylistItem.h"

#import <MediaPlayer/MediaPlayer.h>

@class GameViewController;

@protocol GameViewControllerDelegate <NSObject>

- (void)gameViewController:(GameViewController *)controller didQuitWithReason:(QuitReason)reason;

@end

@interface GameViewController : UIViewController <UITableViewDataSource, MPMediaPickerControllerDelegate, GameDelegate> {
    PlaylistItem *_currentPlaylistItem;
}
@property (nonatomic, weak) IBOutlet UILabel *songLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;
@property (nonatomic, weak) IBOutlet UITableView *userTable;
@property (nonatomic, weak) IBOutlet UITableView *playlistTable;

@property (nonatomic, weak) id <GameViewControllerDelegate> delegate;
@property (nonatomic, strong) Game *game;

- (IBAction)exitAction:(id)sender;
- (IBAction)playMusic:(id)sender;

@end