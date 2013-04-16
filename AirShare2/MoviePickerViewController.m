//
//  MoviePickerViewController.m
//  AirShare2
//
//  Created by mata on 4/16/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "MoviePickerViewController.h"

@interface MoviePickerViewController ()

@end

@implementation MoviePickerViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"Videos";
        [self.navigationItem setHidesBackButton:YES animated:YES];
        UIBarButtonItem* backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancel)];

        self.navigationItem.rightBarButtonItem = backButton;
        
        MPMediaPropertyPredicate *movies = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMovie] forProperty:MPMediaItemPropertyMediaType];
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        [query addFilterPredicate:movies];
        _movies = [query items];
        
        MPMediaPropertyPredicate *musicVideos = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMusicVideo] forProperty:MPMediaItemPropertyMediaType];
        MPMediaQuery *query2 = [[MPMediaQuery alloc] init];
        [query2 addFilterPredicate:musicVideos];
        _musicVideos = [query2 items];
        
        MPMediaPropertyPredicate *tvShows = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeTVShow] forProperty:MPMediaItemPropertyMediaType];
        MPMediaQuery *query3 = [[MPMediaQuery alloc] init];
        [query3 addFilterPredicate:tvShows];
        _tvShows = [query3 items];
        
        MPMediaPropertyPredicate *podcasts = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeVideoPodcast] forProperty:MPMediaItemPropertyMediaType];
        MPMediaQuery *query4 = [[MPMediaQuery alloc] init];
        [query4 addFilterPredicate:podcasts];
        _podcasts = [query4 items];
        
        MPMediaPropertyPredicate *iTunesU = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeVideoITunesU] forProperty:MPMediaItemPropertyMediaType];
        MPMediaQuery *query5 = [[MPMediaQuery alloc] init];
        [query5 addFilterPredicate:iTunesU];
        _iTunesU = [query5 items];
        
        [self initCells];
    }
    return self;
}
- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)initCells
{
    static NSString *CellIdentifier = @"VideoCell";
    _movieCells = [NSMutableArray arrayWithCapacity:_movies.count];
    for(MPMediaItem *item in _movies) {
        MovieItemCell *cell = [[MovieItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.movieItem = item;
        [cell addContent];
        [_movieCells addObject:cell];
    }
    _musicVideoCells = [NSMutableArray arrayWithCapacity:_musicVideos.count];
    for(MPMediaItem *item in _musicVideos) {
        MovieItemCell *cell = [[MovieItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.movieItem = item;
        [cell addContent];
        [_musicVideoCells addObject:cell];
    }
    _tvShowCells = [NSMutableArray arrayWithCapacity:_tvShows.count];
    for(MPMediaItem *item in _tvShows) {
        MovieItemCell *cell = [[MovieItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.movieItem = item;
        [cell addContent];
        [_tvShowCells addObject:cell];
    }
    _podcastCells = [NSMutableArray arrayWithCapacity:_podcasts.count];
    for(MPMediaItem *item in _podcasts) {
        MovieItemCell *cell = [[MovieItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.movieItem = item;
        [cell addContent];
        [_podcastCells addObject:cell];
    }
    _iTunesUCells = [NSMutableArray arrayWithCapacity:_iTunesU.count];
    for(MPMediaItem *item in _iTunesU) {
        MovieItemCell *cell = [[MovieItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.movieItem = item;
        [cell addContent];
        [_iTunesUCells addObject:cell];
    }
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 6;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0) {
        return 44;
    } else {
        return 80;
    }
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"";
            break;
        case 1:
            return _movies.count == 0 ? @"" : @"Movies";
            break;
        case 2:
            return _musicVideos.count == 0 ? @"": @"Music Videos";
            break;
        case 3:
            return _tvShows.count == 0 ? @"": @"TV Shows";
            break;
        case 4:
            return _podcasts.count == 0 ? @"" : @"Video Podcasts";
            break;
        case 5:
            return _iTunesU.count == 0 ? @"" : @"iTunesU";
            break;
        default:
            return nil;
            break;
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
            break;
        case 1:
            return _movies.count;
            break;
        case 2:
            return _musicVideos.count;
            break;
        case 3:
            return _tvShows.count;
            break;
        case 4:
            return _podcasts.count;
            break;
        case 5:
            return _iTunesU.count;
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"VideoCell";
    UITableViewCell *cell = nil;//[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if(cell == nil) {
        switch (indexPath.section) {
            case 0:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                break;
            case 1:
                cell = _movieCells[indexPath.row];
                break;
            case 2:
                cell = _musicVideoCells[indexPath.row];
                break;
            case 3:
                cell = _tvShowCells[indexPath.row];
                break;
            case 4:
                cell = _podcastCells[indexPath.row];
                break;
            case 5:
                cell = _iTunesUCells[indexPath.row];
                break;
            default:
                cell = nil;
                break;
        }
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MPMediaItem *selected = nil;
    switch (indexPath.section) {
        case 0:
            selected = nil;
            break;
        case 1:
            selected = _movies[indexPath.row];
            break;
        case 2:
            selected = _musicVideos[indexPath.row];
            break;
        case 3:
            selected = _tvShows[indexPath.row];
            break;
        case 4:
            selected = _podcasts[indexPath.row];
            break;
        case 5:
            selected = _iTunesU[indexPath.row];
            break;
        default:
            selected = nil;
            break;
    }
    [self.delegate addMovie:selected];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
