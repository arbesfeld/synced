//
//  UIDownloadBar.m
//  UIDownloadBar
//
//  airShare
//
//

#import "UIDownloadBar.h"


@implementation UIDownloadBar

@synthesize DownloadRequest,
DownloadConnection,
receivedData,
delegate,
percentComplete,
operationIsOK,
appendIfExist,
possibleFilename;

- (void) forceStop {
	operationBreaked = YES;
}

- (void) forceContinue {
	operationBreaked = NO;
	
//	NSLog(@"%f",bytesReceived);
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: downloadUrl];
	
	[request addValue: [NSString stringWithFormat: @"bytes=%.0f-", bytesReceived ] forHTTPHeaderField: @"Range"];	
	
	DownloadConnection = [NSURLConnection connectionWithRequest:request
												  delegate: self];	
}


- (UIDownloadBar *)initWithURL:(NSURL *)fileURL progressBarFrame:(CGRect)frame timeout:(NSInteger)timeout delegate:(id<UIDownloadBarDelegate>)theDelegate {
    self.reqStart = [NSDate date];
    self = [super initWithFrame:frame];
	if(self) {
		self.delegate = theDelegate;
		downloadUrl = fileURL;
		bytesReceived = percentComplete = 0;
		localFilename = [[[fileURL absoluteString] lastPathComponent] copy];
		receivedData = [[NSMutableData alloc] initWithLength:0];
		self.progress = 0.0;
		self.backgroundColor = [UIColor clearColor];
		DownloadRequest = [[NSURLRequest alloc] initWithURL:fileURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:timeout];
		DownloadConnection = [[NSURLConnection alloc] initWithRequest:DownloadRequest delegate:self startImmediately:YES];
				
		if(DownloadConnection == nil) {
			[self.delegate downloadBar:self didFailWithError:[NSError errorWithDomain:@"UIDownloadBar Error" code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"NSURLConnection Failed", NSLocalizedDescriptionKey, nil]]];

        }
	}
	
	return self;
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {

	if (!operationBreaked) {
			
		[self.receivedData appendData:data];
		
		float receivedLen = [data length];
		bytesReceived = (bytesReceived + receivedLen);
		
		if(expectedBytes != NSURLResponseUnknownLength) {
			self.progress = ((bytesReceived/(float)expectedBytes)*100)/100;
			percentComplete = self.progress*100;
		}
			//NSLog(@" Data receiving... Percent complete: %f", percentComplete);
		
		[delegate downloadBarUpdated:self];
	
	} else {
		[connection cancel];
		NSLog(@" STOP !!!!  Receiving data was stoped");
	}
		
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self.delegate downloadBar:self didFailWithError:error];
	operationFailed = YES;
	[connection release];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	
    NSLog(@"<-- Latency %fs", [[NSDate date] timeIntervalSinceDate:self.reqStart]);
	//NSLog(@"[DO::didReceiveData] %d operation", (int)self);
	//NSLog(@"[DO::didReceiveData] ddb: %.2f, wdb: %.2f, ratio: %.2f",
	//	  (float)bytesReceived,
	//	  (float)expectedBytes,
	//	  (float)bytesReceived / (float)expectedBytes);
	
	NSHTTPURLResponse *r = (NSHTTPURLResponse*) response;
	NSDictionary *headers = [r allHeaderFields];
    self.length = [[headers objectForKey: @"Content-Length"] doubleValue];
    NSLog(@"<-- package size %f bytes", self.length);
	//NSLog(@"[DO::didReceiveResponse] response headers: %@", headers);
	//if (headers){
	//	if ([headers objectForKey: @"Content-Range"]) {
	//		NSString *contentRange = [headers objectForKey: @"Content-Range"];
	//		NSLog(@"Content-Range: %@", contentRange);
	//		NSRange range = [contentRange rangeOfString: @"/"];
	//		NSString *totalBytesCount = [contentRange substringFromIndex: range.location + 1];
	//		expectedBytes = [totalBytesCount floatValue];
	//	} else if ([headers objectForKey: @"Content-Length"]) {
	//		NSLog(@"Content-Length: %@", [headers objectForKey: @"Content-Length"]);
	//		expectedBytes = [[headers objectForKey: @"Content-Length"] floatValue];
	//	} else expectedBytes = -1;
		
	//	if ([@"Identity" isEqualToString: [headers objectForKey: @"Transfer-Encoding"]]) {
	//		expectedBytes = bytesReceived;
	//		operationFinished = YES;
	//	}
	//}
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSLog(@"<-- download time %f seconds", [[NSDate date] timeIntervalSinceDate:self.reqStart]);
    NSNumber *downloadTime = [NSNumber numberWithFloat:[[NSDate date] timeIntervalSinceDate:self.reqStart]];
    double averageThroughput = self.length / [downloadTime doubleValue];
    NSLog(@"<-- average throughput of %f bps", averageThroughput);
    
    [self.delegate downloadBar:self didFinishWithData:self.receivedData suggestedFilename:localFilename];
	operationFinished = YES;
	NSLog(@"Connection did finish loading...");
}


- (void)dealloc {
	[possibleFilename release];
	[localFilename release];
	[receivedData release];
	[DownloadRequest release];
	[super dealloc];
}

@end
