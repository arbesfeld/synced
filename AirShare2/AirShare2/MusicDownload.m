//
//  MusicDownload.m
//  AirShare2
//
//  Created by mata on 3/24/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "MusicDownload.h"
#import "AFNetworking.h"
#import "MusicItem.h"
#import "Game.h"

@implementation MusicDownload

-(id)initWithGame:(Game *)game {
    if (self = [super init]) {
        _game = game;
    }
    return self;
}
// fileName is the name of the .caf file to be requested,
// saveName is the name in the Documents folder where .caf is saved

-(void)downloadFileWithName:(NSString *)fileName andArtistName:(NSString *)artistName {
    NSString *fileNameNoSpaces = [fileName stringByReplacingOccurrencesOfString:@" " withString:@""];
    // make the GET request
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:fileNameNoSpaces, @"id", nil];
    NSMutableString *prams = [[NSMutableString alloc] init];
    for (id keys in dict) {
        [prams appendFormat:@"%@=%@&",keys,[dict objectForKey:keys]];
    }
    NSString *removeLastChar = [prams substringWithRange:NSMakeRange(0, [prams length]-1)];
    NSString *urlString = [NSString stringWithFormat:@"http://protected-harbor-4741.herokuapp.com/airshare-download.php?%@.caf",removeLastChar];
    
    NSLog(@"requestString %@",urlString);
    
    // the name of the locally saved file
    NSString *saveName = [NSString stringWithFormat:@"%@.caf", fileNameNoSpaces];
    saveName = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:saveName];
    
    NSLog(@"saveName: %@", saveName);

    // asynchronous download
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://protected-harbor-4741.herokuapp.com/"]];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                            path:urlString
                                                      parameters:nil];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success, data length: %d", [responseObject length]);
        
        // write the song to disk
        [responseObject writeToFile:saveName atomically:NO];
        NSMutableData *songData = [[NSMutableData alloc] initWithContentsOfFile:saveName];
        
        // add the musicItem to the table
        MusicItem *musicItem = [MusicItem musicItemWithName:fileName
                                                   subtitle:artistName
                                                     andURL:[[NSURL alloc] initWithString:saveName] ];
        NSLog(@"Added music item with description: %@", [musicItem description]);
        [_game.playlist addObject:musicItem];
        [_game.delegate reloadTable];
        NSError *error;
        _audioPlayer = [[AVAudioPlayer alloc] initWithData:songData error:&error];
        _audioPlayer.delegate = self;
        if (_audioPlayer == nil) {
            NSLog(@"AudioPlayer did not load properly: %@", [error description]);
        } else {
            [_audioPlayer prepareToPlay];
            [_audioPlayer play];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    [operation start];
}

@end
