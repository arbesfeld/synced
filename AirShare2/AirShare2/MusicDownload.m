//
//  MusicDownload.m
//  AirShare2
//
//  Created by mata on 3/24/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "MusicDownload.h"
#import "AFNetworking.h"

@implementation MusicDownload

-(void)downloadFileWithMusicItem:(MusicItem *)musicItem andSessionID:(NSString *)sessionID completion:(void (^)(void))completionBlock{
    // make the GET request URL
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:musicItem.ID, @"id", sessionID, @"sessionid", nil];
    NSMutableString *prams = [[NSMutableString alloc] init];
    for (id keys in dict) {
        [prams appendFormat:@"%@=%@&",keys,[dict objectForKey:keys]];
    }
    NSString *removeLastChar = [prams substringWithRange:NSMakeRange(0, [prams length]-1)];
    NSString *urlString = [NSString stringWithFormat:@"%@airshare-download.php?%@.m4a", BASE_URL, removeLastChar];
    
    NSLog(@"GET Request = %@",urlString);
    
    // the name of the locally saved file
    NSString *saveName = [NSString stringWithFormat:@"%@.m4a", musicItem.ID];
    saveName = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:saveName];

    // asynchronous download
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL]];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                            path:urlString
                                                      parameters:nil];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:saveName append:NO];
    [operation setDownloadProgressBlock:^(NSUInteger bytesDownloaded, long long totalBytesDownloaded, long long totalBytesExpectedToDownload) {
        musicItem.loadProgress = (double)totalBytesDownloaded / totalBytesExpectedToDownload;
        //NSLog(@"Downloaded %lld bytes of %lld bytes", totalBytesDownloaded, totalBytesExpectedToDownload);
    }];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Download Success");
        musicItem.loadProgress = 1.0;
        completionBlock();
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Download Error: %@", error);
    }];
    [operation start];
}

@end
