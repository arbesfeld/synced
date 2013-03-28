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

-(void)downloadFileWithMusicItem:(MusicItem *)musicItem completion:(void (^)(void))completionBlock{
    // make the GET request URL
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:musicItem.ID, @"id", nil];
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
    [operation setDownloadProgressBlock:^(NSUInteger bytesDownloaded, long long totalBytesDownloaded, long long totalBytesExpectedToDownload) {
        musicItem.loadProgress = (double)totalBytesDownloaded / musicItem.fileSize;
        NSLog(@"Downloaded %lld bytes of %d bytes", totalBytesDownloaded, musicItem.fileSize);
    }];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Download Success, data length: %d", [responseObject length]);
        musicItem.loadProgress = 1.0;
        // write the song to disk
        [responseObject writeToFile:saveName atomically:NO];
        completionBlock();
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Download Error: %@", error);
    }];
    [operation start];
}

@end
