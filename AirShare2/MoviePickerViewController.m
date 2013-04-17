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
        
        self.title = @"Videos";
        [self.navigationItem setHidesBackButton:YES animated:YES];
        UIBarButtonItem* backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancel)];
        self.navigationItem.rightBarButtonItem = backButton;
        
        MPMediaPropertyPredicate *moviePredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMovie] forProperty:MPMediaItemPropertyMediaType];
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        [query addFilterPredicate:moviePredicate];
        NSArray *movies = [query items];
        
        MPMediaPropertyPredicate *musicVideoPredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMusicVideo] forProperty:MPMediaItemPropertyMediaType];
        MPMediaQuery *query2 = [[MPMediaQuery alloc] init];
        [query2 addFilterPredicate:musicVideoPredicate];
        NSArray *musicVideos = [query2 items];
        
        MPMediaPropertyPredicate *tvShowPredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeTVShow] forProperty:MPMediaItemPropertyMediaType];
        MPMediaQuery *query3 = [[MPMediaQuery alloc] init];
        [query3 addFilterPredicate:tvShowPredicate];
        NSArray *tvShows = [query3 items];
        
        MPMediaPropertyPredicate *podcastPredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeVideoPodcast] forProperty:MPMediaItemPropertyMediaType];
        MPMediaQuery *query4 = [[MPMediaQuery alloc] init];
        [query4 addFilterPredicate:podcastPredicate];
        NSArray *podcasts = [query4 items];
        
        MPMediaPropertyPredicate *iTunesUPredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeVideoITunesU] forProperty:MPMediaItemPropertyMediaType];
        MPMediaQuery *query5 = [[MPMediaQuery alloc] init];
        [query5 addFilterPredicate:iTunesUPredicate];
        NSArray *iTunesU = [query5 items];
        
        UISearchBar *tempSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 0)];
        self.searchBar = tempSearchBar;
        self.searchBar.delegate = self;
        [self.searchBar sizeToFit];
        self.tableView.tableHeaderView = self.searchBar;
        
        NSArray *empty = [[NSArray alloc] init];
        _allData = [[NSArray alloc] initWithObjects:empty, movies, musicVideos, tvShows, podcasts, iTunesU, nil];
        [self initCells];
        
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
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)initCells
{
    static NSString *CellIdentifier = @"VideoCell";
    _allCells = [[NSMutableArray alloc] initWithCapacity:6];
    _allCells[0] = [[NSMutableArray alloc] initWithObjects:
                    [[MovieItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier], nil];
    for(int i = 1; i < 6; i++) {
        _allCells[i] = [[NSMutableArray alloc] initWithCapacity:((NSArray *)_allData[i]).count];
        for(MPMediaItem *item in _allData[i]) {
            MovieItemCell *cell = [[MovieItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.movieItem = item;
            [cell addContent];
            [_allCells[i] addObject:cell];
        }
    }
    _searchCells = [[NSMutableArray alloc] initWithArray:_allCells copyItems:YES];
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ((NSArray *)_searchCells).count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(((NSArray *)_allData[section]).count == 0) {
        return nil;
    }
    return _labels[section];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *)_searchCells[section]).count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"VideoCell";
    UITableViewCell *cell = nil;//[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if(cell == nil) {
        if(indexPath.section == 0) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        } else {
            cell = (UITableViewCell *)(_searchCells[indexPath.section][indexPath.row]);
        }
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MPMediaItem *selected = nil;
    if(indexPath.section == 0) {
        //
    } else {
        selected = ((MovieItemCell *)_searchCells[indexPath.section][indexPath.row]).movieItem;
    }
    
    [self.delegate addMovie:selected];
    [searchDisplayController setActive:NO animated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SearchDisplayControllerDelegate
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [_searchCells removeAllObjects];
    if([searchString isEqualToString:@""]) {
        _searchCells = [[NSMutableArray alloc] initWithArray:_allCells copyItems:YES];
        return YES;
    }
    for(int i = 0; i < _allCells.count; i++)
    {
        NSArray *group = _allCells[i];
        NSMutableArray *newGroup = [[NSMutableArray alloc] initWithCapacity:((NSArray *)_allCells[i]).count];
        
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
        [_searchCells addObject:newGroup];
    }
    return YES;
}
- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    tableView.rowHeight = 80;
}
@end
