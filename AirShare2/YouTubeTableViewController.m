//
//  YouTubeTableViewController.m
//  AirShare2
//
//  Created by mata on 4/21/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "YouTubeTableViewController.h"
#import "UIImageView+WebCache.h"

const int ITEM_COUNT = 10;

@interface YouTubeTableViewController ()

@end

@implementation YouTubeTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        UISearchBar *tempSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 0)];
        self.searchBar = tempSearchBar;
        self.searchBar.delegate = self;
        [self.searchBar sizeToFit];
        self.tableView.tableHeaderView = self.searchBar;
        
        [self resetContent];
        
//        searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
//        searchDisplayController.delegate = self;
//        searchDisplayController.searchResultsDataSource = self;
//        searchDisplayController.searchResultsDelegate = self;
    }
    return self;
}

- (void)resetContent
{
    _videoTitle = [[NSMutableArray alloc] initWithCapacity:ITEM_COUNT];
    _videoURL = [[NSMutableArray alloc] initWithCapacity:ITEM_COUNT];
    _videoDescription = [[NSMutableArray alloc] initWithCapacity:ITEM_COUNT];
    _videoThumbnailImageURL = [[NSMutableArray alloc] initWithCapacity:ITEM_COUNT];
    _videoDuration = [[NSMutableArray alloc] initWithCapacity:ITEM_COUNT];
}

- (void)queryContent:(NSString *)searchString
{
    NSDictionary *command = [NSDictionary dictionaryWithObjectsAndKeys:
                             searchString, @"q",
                             @"json", @"alt",
                             [NSString stringWithFormat:@"%d", 1], @"start-index",
                             [NSString stringWithFormat:@"%d", ITEM_COUNT], @"max-results",
                             nil];
    
    NSMutableString *prams = [[NSMutableString alloc] init];
    for (id keys in command) {
        [prams appendFormat:@"%@=%@&",keys,[command objectForKey:keys]];
    }
    NSString *removeLastChar = [prams substringWithRange:NSMakeRange(0, [prams length]-1)];
    NSString *requestString = [NSString stringWithFormat:@"http://gdata.youtube.com/feeds/api/videos?%@", removeLastChar];
    //NSLog(@"request = %@", requestString);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:requestString]];
    NSData *returnData = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil ];
    NSString *returnString = [[NSString alloc] initWithData:returnData encoding: NSUTF8StringEncoding];
    //NSLog(@"returnstring = %@", returnString);
    
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    
    NSDictionary *JSONresponse = [parser objectWithString:returnString];
    //NSLog(@"JSONresponse = %@", JSONresponse);
    
    // You can retrieve individual values using objectForKey on the status NSDictionary
    // This gives you the entire Youtube "feed"
    NSDictionary *JSONresponseSection = [JSONresponse objectForKey:@"feed"];
    //NSLog(@"JSPNresponsesection = %@", JSONresponseSection);
    
    // This entry returns all the list of Videos into an Array
    NSArray *JSONAllVideos = [JSONresponseSection objectForKey:@"entry"];
    
    for(int i = 0; i < [JSONAllVideos count]; i++) {
        //This entry creates a dictionary to contain all metadata for one video
        NSDictionary *JSONOneVideo = [JSONAllVideos objectAtIndex:i];
        //NSLog(@"JSONOneVideo = %@", JSONOneVideo);
        
        //This entry creates a dictionary to seek out the title and add it to global IVAR _videoArrayTitle
        NSDictionary *JSONtitleSet = [JSONOneVideo objectForKey:@"title"];
        //NSString *JSONVideoTitle = [JSONtitleSet objectForKey:@"$t"];
        [_videoTitle addObject:[JSONtitleSet objectForKey:@"$t"]];
        //NSLog(@"JSONVideoTitle = %@", _videoTitle);
        
        //This entry creates a dictionary to seek out the media set which includes description, player, URL
        NSDictionary *JSONmediaSet= [JSONOneVideo objectForKey:@"media$group"];
        //NSLog(@"JSONmediaSet = %@", JSONmediaSet);
        
        //This entry creates a dictionary to seek out the title and add it to global IVAR _
        NSDictionary *JSONdescriptionSet= [JSONmediaSet objectForKey:@"media$description"];
        [_videoDescription addObject:[JSONdescriptionSet objectForKey:@"$t"]];
        //NSLog(@"GlobalVideoDescription = %@", _videoDescription);
        
        //This entry creates a dictionary to seek out the mediaplayerURL and add it to global IVAR _
        NSArray *JSONmediaPlayerSet= [JSONmediaSet objectForKey:@"media$player"];
        NSArray *tempArray = [JSONmediaPlayerSet objectAtIndex:0];
        NSString *tempURL = [tempArray valueForKey:@"url"];
        [_videoURL addObject:tempURL];
        //NSLog(@"JSONmedialPlayerSet array = %@", JSONmediaPlayerSet);
        //[_YTArrayVideoURL addObject:[JSONmediaPlayerSet objectAtIndex:0]];
        //NSLog(@"_YTArrayURL array = %@", _videoURL);
        
        
        //This entry creates an array for duration variable and add it to global IVAR _
        NSArray *JSONdurationSet= [JSONmediaSet objectForKey:@"yt$duration"];
        //NSLog(@"JSONdurationSet = %@", JSONdurationSet);
        NSString *numberString = [self convertTimeFormat:[JSONdurationSet valueForKey:@"seconds"]];
        [_videoDuration addObject:numberString];
        //NSLog(@"videoDuration = %@", _videoDuration);
        
        //This entry creates an array for thumbnail images and add it to global IVAR _
        NSArray *JSONthumbnailImageURLSet = [JSONmediaSet objectForKey:@"media$thumbnail"];
        NSArray *thumbnailImageURLArray = [JSONthumbnailImageURLSet objectAtIndex:0];
        //NSLog(@"thumbnailURLArray = %@", thumbnailImageURLArray);
        [_videoThumbnailImageURL addObject:[thumbnailImageURLArray valueForKey:@"url"]];
        //NSLog(@"thumbnailUImageURL = %@", _videoThumbnailImageURL);
    }
    [self.tableView reloadData];
}

- (NSString *) convertTimeFormat:(NSString *)aNumberString {
	int num_seconds = [aNumberString intValue];
	//NSLog(@"num_seconds passed is: %i", num_seconds);
	//float days = aFloatValue / (60 * 60 * 24);
	//float num_seconds -= days * (60 * 60 * 24);
	int hours = num_seconds / (60 * 60);
	//NSLog(@"Hour is: %i", hours);
	num_seconds -= hours * (60 * 60);
	int minutes = num_seconds / 60;
	//NSLog(@"Minutes is: %i", minutes);
	num_seconds -= minutes * (60);
	//NSLog(@"Seconds remaining is: %i", num_seconds);
    
	//convert time value passed into format
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setHour:hours];
	[comps setMinute:minutes];
	[comps setSecond:num_seconds];
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDate *date = [gregorian dateFromComponents:comps];
	//NSLog(@"NSDate comps is. date is: %@", date);
	
	NSString *timeToReturn = date.description;
	timeToReturn = [timeToReturn stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSArray *timeArray = [timeToReturn componentsSeparatedByString:@" "];
	//NSLog(@"timeArray is: %@", timeArray);
	timeToReturn = [timeArray objectAtIndex:1];
	//separate the colons into array and parse and return the min:sec only
	timeArray = [timeToReturn componentsSeparatedByString:@":"];
	timeToReturn = [timeArray objectAtIndex:1];
	timeToReturn = [timeToReturn stringByAppendingString:@":"];
	timeToReturn = [timeToReturn stringByAppendingString:[timeArray objectAtIndex:2]];
	//NSLog(@"TimeToReturn is: %@", timeToReturn);
	return timeToReturn;
}

- (NSString *)genRandStringLength:(int)len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i = 0; i < len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_videoTitle count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //static NSString *CellIdentifier = @"Cell";
    MovieItemCell *cell = nil;//[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    int r = indexPath.row;
    if(cell == nil) {
        cell = [[MovieItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil title:_videoTitle[r] artist:_videoDescription[r] duration:_videoDuration[r] imageURL:[NSURL URLWithString:_videoThumbnailImageURL[r]]];
        
        //[cell.thumbImgView setImageWithURL:cell.imageURL placeholderImage:[UIImage imageNamed:@"upvote.png"]];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int r = indexPath.row;
    YoutubeItem *youtubeItem = [YoutubeItem youtubeItemWithName:_videoTitle[r]
                                                    andSubtitle:@""
                                                          andID:[self genRandStringLength:6]
                                                        andDate:[NSDate date]
                                                         andURL:_videoURL[r]];
    [self.delegate addYoutubeVideo:youtubeItem];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - SearchDisplayControllerDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self queryContent:searchBar.text];
}
@end
