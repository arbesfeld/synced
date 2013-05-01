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

-(void)downloadFileWithMediaItem:(MediaItem *)mediaItem andSessionID:(NSString *)sessionID progress:(void (^)(void))progress completion:(void (^)(void))completion failure:(void (^)(void))failure {
    return; // TEMPORARY TO SKIP THE REST OF THIS CODE
    
    // make the GET request URL
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:sessionID, @"sessionid", mediaItem.ID, @"id", nil];
    NSMutableString *prams = [[NSMutableString alloc] init];
    for (id keys in dict) {
        [prams appendFormat:@"%@=%@&",keys,[dict objectForKey:keys]];
    }
    NSString *removeLastChar = [prams substringWithRange:NSMakeRange(0, [prams length]-1)];
    NSString *urlString = [NSString stringWithFormat:@"%@airshare-download.php?%@", BASE_URL, removeLastChar];
    
    NSLog(@"GET Request = %@",urlString);
    
    // the name of the locally saved file
    NSString *tempPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@.m4a", mediaItem.ID];
    NSString *songPath = [tempPath stringByAppendingPathComponent:fileName];

    // asynchronous download
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL]];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                            path:urlString
                                                      parameters:nil];
    __block int it = 0;
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:songPath append:NO];
    [operation setDownloadProgressBlock:^(NSUInteger bytesDownloaded, long long totalBytesDownloaded, long long totalBytesExpectedToDownload) {
        mediaItem.loadProgress = (double)totalBytesDownloaded / totalBytesExpectedToDownload;
        if(it % 300 == 0) {
            progress();
        }
        it++;
        //NSLog(@"Downloaded %lld bytes of %lld bytes", totalBytesDownloaded, totalBytesExpectedToDownload);
    }];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Download Success");
        mediaItem.loadProgress = 1.0;
        completion();
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Download Error: %@", error);
        failure();
        return;
    }];
    [operation start];
    mediaItem.operation = operation;
}

- (void)downloadBeatsWithMediaItem:(MediaItem *)mediaItem andSessionID:(NSString *)sessionID completion:(void (^)(void))completionBlock
{
    // make the GET request URL
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:sessionID, @"sessionid", mediaItem.ID, @"id", nil];
    NSMutableString *prams = [[NSMutableString alloc] init];
    for (id keys in dict) {
        [prams appendFormat:@"%@=%@&",keys,[dict objectForKey:keys]];
    }
    NSString *removeLastChar = [prams substringWithRange:NSMakeRange(0, [prams length]-1)];
    NSString *urlString = [NSString stringWithFormat:@"%@airshare-beats.php?%@", BASE_URL, removeLastChar];
    
    NSLog(@"GET Request = %@",urlString);
    
    // the name of the locally saved file
    NSString *saveName = [NSString stringWithFormat:@"%@-beats.txt", mediaItem.ID];
    saveName = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:saveName];
    NSLog(@"saving beats to %@", saveName);
    
    // asynchronous download
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL]];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                            path:urlString
                                                      parameters:nil];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:saveName append:NO];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Download Success");
        completionBlock();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Download Error: %@", error);
    }];
    [operation start];
}

@end
