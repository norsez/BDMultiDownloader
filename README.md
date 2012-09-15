#BDMultiDownloader - Simple Objective-C block-based concurrent multiple-URL data downloader based only on NSURLConnection

Your app needs to download concurrently from multiple URLs (local or not). This class does it in a simple way using blocks and NSURLConnection.

##Features
- Receive downloaded data using blocks
- Download progress for each download
- Cancel a download or all downloads
- Automatic caching
- A convenient method for downloading multiple images 
- Only tested in iOS, but should also work in Mac OS. 

---

##Requirements
- Requires ARC

---

##How It Works

No complicated setup. Just include the class header in your source code like this:

	#import "BDMultiDownloader.h"
	
Retrieve the singleton instance. __Never__ `alloc init`

	[BDMultiDownloader shared]


###Downloading multiple images concurrently	
The most common use case is to concurrently download multiple images off the web somewhere. Just do something like:

	NSArray * pathsToImages = … //NSString paths to your images
	
	for	(NSString *path in pathsToImages){
		[[BDMultiDownloader shared] imageWithPath:path
	                                   completion:^(UIImage * image, BOOL fromCache) {
											//here is the block where you receive your downlaoded image
											//the fromCache var is a flag for whether the image is fresh
											//downloaded off the web or from the singleton's 
											//automatic cache
											
											//use your downloaded image…
	                                   }];
    }

In the completion block, you get each image's UIImage and a flag for whether it's from the class's automatic cache (Note: because sometimes you want to update UI differently for the images that's just been downloaded as opposed to those already shown on your screen).

Note that the download request path must be absolute URL string with either `http://` or `file://` protocol.

###Downloading other types of data concurrently
The most general use case is to download data in the form of `NSData`. This could be anything from HTML content, to a data file, to JSON. Below is an example for retrieving JSON:

	[[BDMultiDownloader shared] queueRequest:pathToJSON
								  completion:^(NSData *data){
								  	if	(data == nil){
								  	//bail out if data is nil.
								  	  return;
								  	}
								  	
								  	NSDictionary jsonObject = [NSJSONSerialization 
								  				JSONObjectWithData:data
                                            	           options:0
                                              	             error:nil];
                                              	             
                                    //do something useful with your download JSON          	             
                                    [self processJSON:jsonObject];
								  }];	
								  
###Canceling an Ongoing Download
You go like…
	
	[[BDMultiDownloader shared] dequeueWithPath:@"http://imgurl.com/apicture.jpg"];

The ongoing download is immediately cancelled together with its completion block deleted and non-triggered.

###Cancel all Downloads

	[[BDMultiDownloader shared] clearQueue];
	
This immediately cancels all ongoing downloads and their associated completion blocks.								  

###Network activity indicator
Tracking the class singleton's network activity can be done by setting the `onNetworkActivity` block.

	[BDMultiDownloader shared].onNetworkActivity = ^(BOOL isActive){
		self.networkStatusText = isActive?@"Downloading…":@"Done.";
	};

If you also use `AFNetworking`'s `AFNetworkActivityIndicatorManager`, this is where you increment/decrement your activity count.

###On Network Error
Since this class is originally designed for downloading multiple homogeneous types of data, there's no specific way to handle each particular download failure. However, when an error occurs, you can be notified through the `onNetworkError` block. The block gets triggered for each error received for every download request.

	[BDMultiDownloader shared].onNetworkError= ^(NSError *error){
		//your app can do something with the error.
		[self alertError:error];
	};

###Tracking Download Progresses
The `onDownloadProgressWithProgressAndSuggestedFilename` block can be used for tracking progress for each download request. The progress is returned in the range of 0.0 to 1.0 (start to finish). The suggested filename is usually the last component in your download request path, but it could be nil in some cases. The block is triggered for all the ongoing downloads. 

	
###`NSURLRequest` version of the API
Some requests are complex than just http URL paths. iOS developers use `NSURLRequest` or `NSMutableURLRequest` classes to build these complex requests such as defining HTTP headers, HTTP methods, etc.

###Convenient method for JSON requests
The convenient method for JSON request utilizes the `NSURLRequest` version call to send async request to the endpoint and completes with a block with the returned JSON object (usually variations of NSArray or NSDictionary classes depending on the supplied NSJSONReadingOptions.)


---

##How to use
- Be sure to checkout the latest __tag__, as opposed to the latest commit. Only tagged points are stable.
- Without CocoaPods, just include h/.m files in Classes folder to your source code
- Look at the iPhone demo. Read the comments. Send me questions, if any.
 
##Apps using BDMultiDownloader

- [Photosophia iOS for Flickr Groups](http://www.google.com/url?sa=t&rct=j&q=photosophia%20app&source=web&cd=4&cad=rja&ved=0CDYQFjAD&url=http%3A%2F%2Fitunes.apple.com%2Fus%2Fapp%2Fphotosophia-for-flickr-groups%2Fid530161971%3Fmt%3D8&ei=2DA8UPDzEcLsrAed3YGwAQ&usg=AFQjCNEqFsfzipOIXDlFn1gzTmcioNsV2A&sig2=4J9p4wXIWYC-rGLzF5LXbg) (Shameless plug :)
- Please let me know of your apps so I can extend this list. Thanks!
 
---

##License
BDMultiDownloader is licensed under BSD. More info in LICENSE file.