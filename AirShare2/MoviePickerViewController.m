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
        _labels = [[NSArray alloc] initWithObjects:@"", @"Movies", @"Music Videos", @"TV Shows", @"Podcasts", @"iTunesU", nil];
        _shouldLoadImages = YES;
        
        self.title = @"Videos";
        [self.navigationItem setHidesBackButton:YES animated:YES];
        UIBarButtonItem* backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancel)];
        self.navigationItem.rightBarButtonItem = backButton;
        
        MPMediaPropertyPredicate *moviePredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMovie]
                                                                                    forProperty:MPMediaItemPropertyMediaType];
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        [query addFilterPredicate:moviePredicate];
        NSArray *movies = [query items];
        
        MPMediaPropertyPredicate *musicVideoPredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMusicVideo]
                                                                                         forProperty:MPMediaItemPropertyMediaType];
        MPMediaQuery *query2 = [[MPMediaQuery alloc] init];
        [query2 addFilterPredicate:musicVideoPredicate];
        NSArray *musicVideos = [query2 items];
        
        MPMediaPropertyPredicate *tvShowPredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeTVShow]
                                                                                     forProperty:MPMediaItemPropertyMediaType];
        MPMediaQuery *query3 = [[MPMediaQuery alloc] init];
        [query3 addFilterPredicate:tvShowPredicate];
        NSArray *tvShows = [query3 items];
        
        MPMediaPropertyPredicate *podcastPredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeVideoPodcast]
                                                                                      forProperty:MPMediaItemPropertyMediaType];
        MPMediaQuery *query4 = [[MPMediaQuery alloc] init];
        [query4 addFilterPredicate:podcastPredicate];
        NSArray *podcasts = [query4 items];
        
        MPMediaPropertyPredicate *iTunesUPredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeVideoITunesU]
                                                                                      forProperty:MPMediaItemPropertyMediaType];
        MPMediaQuery *query5 = [[MPMediaQuery alloc] init];
        [query5 addFilterPredicate:iTunesUPredicate];
        NSArray *iTunesU = [query5 items];
        
        UISearchBar *tempSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 0)];
        self.searchBar = tempSearchBar;
        self.searchBar.delegate = self;
        [self.searchBar sizeToFit];
        self.tableView.tableHeaderView = self.searchBar;
        
        NSArray *empty = [[NSArray alloc] init];
        _allData = [[NSMutableArray alloc] initWithObjects:empty, movies, musicVideos, tvShows, podcasts, iTunesU, nil];
        _searchData = [[NSMutableArray alloc] initWithArray:_allData copyItems:YES];
        searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
        searchDisplayController.delegate = self;
        searchDisplayController.searchResultsDataSource = self;
        searchDisplayController.searchResultsDelegate = self;
    }
    return self;
}

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ((NSArray *)_searchData).count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(((NSArray *)_searchData[section]).count == 0) {
        return nil;
    }
    return _labels[section];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) {
        NSString * searchString = [_searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (![searchString length]) {
            return 1;
        } else {
            return 0;
        }
    } else {
        return ((NSArray *)_searchData[section]).count;

    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"VideoCell";
    MovieItemCell *cell = nil; //[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if(cell == nil) {
        if(indexPath.section == 0) {
            cell = [[MovieItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier title:@"" artist:@"Search for Youtube Videos" duration:@"" image:[UIImage imageNamed:@"youtubeLogo.png"]];
        } else {
            cell = [[MovieItemCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                           reuseIdentifier:CellIdentifier
                                                                 movieItem:_searchData[indexPath.section][indexPath.row]];
        }
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MPMediaItem *selected = nil;
    if(indexPath.section == 0) {
        YouTubeTableViewController *youtubeTableViewController = [[YouTubeTableViewController alloc] initWithStyle:UITableViewStylePlain];
        youtubeTableViewController.delegate = self;
        [self.navigationController pushViewController:youtubeTableViewController animated:YES];
    } else {
        selected = _searchData[indexPath.section][indexPath.row];
    
        NSURL *assetURL = [selected valueForProperty:MPMediaItemPropertyAssetURL];
        AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
        
        if([songAsset hasProtectedContent]) {
            // can't play something with protected content
            return;
        }
        
        [self.delegate addMovie:selected];
        [searchDisplayController setActive:NO animated:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - SearchDisplayControllerDelegate
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [_searchData removeAllObjects];
    if([searchString isEqualToString:@""]) {
        _searchData = [[NSMutableArray alloc] initWithArray:_allData copyItems:YES];
        return YES;
    }
    for(int i = 0; i < _allData.count; i++)
    {
        NSArray *group = _allData[i];
        NSMutableArray *newGroup = [[NSMutableArray alloc] initWithCapacity:((NSArray *)_allData[i]).count];
        
        for(MovieItemCell *element in group)
        {
            NSRange rangeTitle = [element.title rangeOfString:searchString
                                                      options:NSCaseInsensitiveSearch];
            NSRange rangeArtist = [element.artist rangeOfString:searchString
                                                        options:NSCaseInsensitiveSearch];
            
            if (rangeTitle.length > 0 || rangeArtist.length > 0) {
                [newGroup addObject:element];
            }
        }
        [_searchData addObject:newGroup];
    }
    return YES;
}
- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    tableView.rowHeight = 80;
}

#pragma mark - UIScrollViewDelegate
//- (void)scrollViewDidScroll
//{
//    NSLog(@"Will begin scrolling");
//    _shouldLoadImages = NO;
//}
//- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
//{
//    NSLog(@"Will begin dragging");
//    _shouldLoadImages = NO;
//}
//- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
//{
//    NSLog(@"Did end dragging");
//    NSLog(@"Velocity = %f %f", velocity.x, velocity.y);
//    if(velocity.y < 1.0) {
//        _shouldLoadImages = YES;
//        [self.tableView reloadData];
//    }
//}
//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
//{
//    NSLog(@"Did end ecelerating");
//    if(!_shouldLoadImages) {
//        [self.tableView reloadData];
//        _shouldLoadImages = YES;
//    }
//}
//- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
//{
//    NSLog(@"Did end scrolling");
//    if(!_shouldLoadImages) {
//        [self.tableView reloadData];
//        _shouldLoadImages = YES;
//    }
//}

#pragma mark - YoutubeDelegate
- (void)addYoutubeVideo:(MediaItem *)youtubeItem
{
    [self.delegate addYoutubeVideo:youtubeItem];
    
}
@end
