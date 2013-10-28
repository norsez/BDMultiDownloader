//  BDMultiDownloader.h
//
//  Created by Norsez Orankijanan on 5/19/12.
//
//  Copyright (c) 2012, Norsez Orankijanan (Bluedot) All Rights Reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, 
//  this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, 
//  this list of conditions and the following disclaimer in the documentation 
//  and/or other materials provided with the distribution.
//
//  3. Neither the name of Bluedot nor the names of its contributors may be used 
//  to endorse or promote products derived from this software without specific
//  prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
//  POSSIBILITY OF SUCH DAMAGE.

#import <Foundation/Foundation.h>

/**
 * A block based singleton class that takes care of a pool of connections concurrently downloading 
 * and caching data from.
 */
@interface BDMultiDownloader : NSObject <NSURLConnectionDelegate>

/**
 Add a path for data download. Download begins when there's a free connection 
 available in the pool. The downloaded data is automatically cached.
 This is the core method of this class. 
 
 @param urlPath path to download.  
 @param completionWithDownloadedData block returned with downloaded data. 
 */
- (void) queueRequest:(NSString*)urlPath completion:(void(^)(NSData*))completionWithDownloadedData;

/**
 URL request version of queueRequest:completion:. This version is suitable for a more complex request 
 (e.g. special http body encoding, or headers etc.)
 @param urlRequest a url request
 @param completionWithDownloadedData block returned with downloaded data.  
 */
- (void) queueURLRequest:(NSURLRequest*)urlRequest completion:(void(^)(NSData*))completionWithDownloadedData;

/**
 Convenient method for retriving JSON object.
 @param urlRequest a url request to JSON data
 @param completionWithJSONObject block returned with JSON object, nil if error.
 @param options NSJSONReadingOptions settings
 */
- (void) jsonWithRequest:(NSURLRequest*)jsonRequest options:(NSJSONWritingOptions)options completion:(void(^)(id))completionWithJSONObject;

/**
 * Convenient method for downloading image files. 
 * @param urlPath path to the image
 * @param completionWithImageYesIfFromCache block returned with downloaded image, and YES if the image is returned from cache.
 */
- (void) imageWithPath:(NSString*)urlPath completion:(void(^)(UIImage*, BOOL))completionWithImageYesIfFromCache;

/**
 * Cancel all pending URL connections.
 */
- (void) clearQueue;

/**
 Clear data cache.
 */
- (void) clearCache;

/**
 * Cancel a download using download path.
 * @path the download path to dequeue (to cancel.)
 */
- (void) dequeueWithPath:(NSString*)path;


#pragma mark - queue manipulation
/**
 @name Connection Queue Manipulation
 
 In order to keep with the existing API and the nature of use of this class (bulk loading),
 connection queue manipulation is designed to give more control to bulk loading.
 
 */

/**
 Pause the class from loading the next request in the connection queue.
 This affects only the pending connections, not the pending completion blocks.
 */
@property (nonatomic, assign) BOOL pause;





#pragma mark - block based delegators, they are all optional (can be nil)
/**
 the queue which completion block is executed in. If NULL, execute in main queue.
 */
@property (nonatomic, assign) dispatch_queue_t completionQueue;

//block called when a file is enqueued more than a time
@property (nonatomic, copy) void (^onDuplicateDownload)(NSString*);
//block called when encountered error
@property (nonatomic, copy) void (^onNetworkError)(NSError*);
//block called to indicates network activity. YES when there's network activity from this class. No otherwise. This can be used to toggle iOS's network status indicator.
@property (nonatomic, copy) void (^onNetworkActivity)(BOOL);
//block called to indicate progress (ranging from 0.0 to 1.0 Finished) of each file (indicated by suggested filename)
@property (nonatomic, copy) void (^onDownloadProgressWithProgressAndSuggestedFilename)(double, NSString*);

#pragma mark - optional configs
@property (nonatomic, assign) NSUInteger cacheSizeLimit;
/**
 The number of ongoing downloads at one time. The class holds download requests in a queue, and wait
 for there are download slots available before actually start making download connections.
 */
@property (nonatomic, assign) NSUInteger maximumNumberOfThreads;
@property (nonatomic, strong) NSDictionary *httpHeaders;
@property (nonatomic, assign) NSTimeInterval connectionTimeout;
@property (nonatomic, assign) NSURLCacheStoragePolicy urlCacheStoragePolicy;
/**
 If YES, this class will ignore request url which is still in the loading queue.
 */
@property (nonatomic, assign) BOOL preventQueuingDuplicateRequest;


+ (BDMultiDownloader *)shared;
@end