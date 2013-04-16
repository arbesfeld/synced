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
        _searchData = [[NSMutableArray alloc] init];
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
    searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
    searchDisplayController.delegate = self;
    searchDisplayController.searchResultsDataSource = self;
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
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ((NSArray *)_allData).count;
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
    if(((NSArray *)_allData[section]).count == 0) {
        return @"";
    }
    switch (section) {
        case 0:
            return @"";
            break;
        case 1:
            return @"Movies";
            break;
        case 2:
            return @"Music Videos";
            break;
        case 3:
            return @"TV Shows";
            break;
        case 4:
            return @"Video Podcasts";
            break;
        case 5:
            return @"iTunesU";
            break;
        default:
            return nil;
            break;
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *)_allData[section]).count;
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
            cell = (UITableViewCell *)(_allCells[indexPath.section][indexPath.row]);
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
        selected = _allData[indexPath.section][indexPath.row];
    }
    
    [self.delegate addMovie:selected];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SearchDisplayControllerDelegate
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [_searchData removeAllObjects];
    /*before starting the search is necessary to remove all elements from the
     array that will contain found items */
    
    NSArray *group;
    
    /* in this loop I search through every element (group) (see the code on top) in
     the "originalData" array, if the string match, the element will be added in a
     new array called newGroup. Then, if newGroup has 1 or more elements, it will be
     added in the "searchData" array. shortly, I recreated the structure of the
     original array "originalData". */
    
    for(group in _allData) //take the n group (eg. group1, group2, group3)
        //in the original data
    {
        NSMutableArray *newGroup = [[NSMutableArray alloc] init];
        NSString *element;
        
        for(element in group) //take the n element in the group
        {                    //(eg. @"Napoli, @"Milan" etc.)
            NSRange range = [element rangeOfString:searchString
                                           options:NSCaseInsensitiveSearch];
            
            if (range.length > 0) { //if the substring match
                [newGroup addObject:element]; //add the element to group
            }
        }
        
        if ([newGroup count] > 0) {
            [_searchData addObject:newGroup];
        }
    
    }
    
    return YES;
}
@end
