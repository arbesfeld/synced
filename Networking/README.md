UIDownloadBar subclassed UIProgressView

Screenshot:

![image](https://raw.github.com/sakrist/UIDownloadBar/master/4.png)

How to use:

```
- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
    
	UIDownloadBar *bar = [[UIDownloadBar alloc] initWithURL:[NSURL URLWithString:@"https://dl-ssl.google.com/chrome/mac/stable/GGRM/googlechrome.dmg"]
							progressBarFrame:CGRectMake(30, 100, 200, 20)
									 timeout:15 
									delegate:self];

	[window addSubview:bar];
	[bar release];

}

- (void)downloadBar:(UIDownloadBar *)downloadBar didFinishWithData:(NSData *)fileData suggestedFilename:(NSString *)filename {
	NSLog(@"%@", filename);
}

- (void)downloadBar:(UIDownloadBar *)downloadBar didFailWithError:(NSError *)error {
	NSLog(@"%@", error);
}

- (void)downloadBarUpdated:(UIDownloadBar *)downloadBar {

}
```

---

Version 1.2

License: BSD

Author: John (aka Gojohnnyboi) in 2009

Updated: Vladimir (aka SAKrisT) in 2011

- - - 

Blog Post: http://www.developers-life.com/sample-usage-uidownloadbar.html

Info:
Have fun while using and extending this package.