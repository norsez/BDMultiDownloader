//
//  BDMutliDownloader.m
//
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

#import "BDMultiDownloader.h"

#define kIntervalDefaultTimeout 60
#define kMaxNumberOfThreads 25
#define kMaxCache 10 * 1024 * 1000

#define BDMDKeyRequest @"BDMDKeyRequest"
#define BDMDKeyCompletion @"BDMDKeyCompletion"


NSString* const BDMultiDownloaderMethodPOST = @"POST";

@interface BDURLConnection : NSURLConnection{
  void(^_completion)(NSData*);
}
@property (nonatomic, copy) void(^completionWithDownloadedData)(NSData*);
@property (nonatomic, assign) double progress;
@property (nonatomic, assign) long long expectedLength;
@property (nonatomic, strong) NSString *MIMEType;
@property (nonatomic, strong) NSString *suggestedFilename;
@property (nonatomic, strong) NSURLRequest* originalRequest;
- (id)copyWithZone:(NSZone*)zone;
@end

@implementation BDURLConnection
- (id)copyWithZone:(NSZone *)zone
{
  return self;
}
@synthesize completionWithDownloadedData;
@synthesize MIMEType;
@synthesize expectedLength;
@synthesize progress;
@synthesize suggestedFilename;
@synthesize originalRequest;
@end


#pragma mark - NSURLRequest Extension
#define BDURLRequestRequestIdKey @"BDURLRequestRequestIdKey"

@interface NSURLRequest (BDMultiDownloader)
- (NSString*)requestId;
@end

@implementation NSURLRequest (BDMultiDownloader)

-(NSString *)requestId
{
  //    if ([[self.HTTPMethod uppercaseString] isEqualToString:BDMultiDownloaderMethodPOST]) {
  //        return [NSString stringWithFormat:@"%@%@%@",self.URL.absoluteString, self.HTTPMethod, self.HTTPBody];
  //    }
  //    return self.URL.absoluteString;
  NSString* rid = [(NSMutableURLRequest*)self valueForHTTPHeaderField:BDURLRequestRequestIdKey];
  return rid;
}
@end

#pragma mark - BDMultiDownloader implementations
@interface BDMultiDownloader ()
{
  //class state data
  NSMutableArray *_currentConnections;
  NSMutableDictionary *_currentConnectionsData; //map NSURLConnection to NSData
  
  //queue management data
  NSMutableArray *_loadingQueue; //list of NSURLRequest to connect
  NSMutableDictionary *_requestCompletions; //map NSURLRequest.requestId to block.
  
  //Caching of loaded data
  NSCache *_dataCache;
  
}

- (void) launchNextConnection;
- (NSUInteger) numberOfItemsInQueue;

@end

@implementation BDMultiDownloader
static NSUInteger requestId;

- (void)_addRequestId:(NSURLRequest**)request
{
  if (![*request isKindOfClass:[NSMutableURLRequest class]]) {
    *request = [(*request) mutableCopy];
  }
  
  //add request id before sending off
  NSNumber * rid = [NSNumber numberWithInt:(requestId++)];
  [(NSMutableURLRequest*) *request addValue:rid.stringValue forHTTPHeaderField:BDURLRequestRequestIdKey];
  
}

- (void)queueRequest:(NSString *)urlPath completion:(void (^)(NSData *))completionWithDownloadedData
{
  if(!urlPath){
    return;
  }
  
  if (self.preventQueuingDuplicateRequest) {
    __block int indexFound = NSNotFound;
    
    [_loadingQueue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      NSURLRequest *r = obj;
      if ([urlPath isEqualToString:r.URL.absoluteString]) {
        *stop = YES;
        indexFound = idx;
        self.onDuplicateDownload(r.URL.absoluteString);
      }
    }];
    
    [_currentConnections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      NSURLConnection *r = obj;
      
      if ([urlPath isEqualToString:r.currentRequest.URL.absoluteString]) {
        *stop = YES;
        indexFound = idx;
        self.onDuplicateDownload(r.currentRequest.URL.absoluteString);
      }
    }];
    
    if  (NSNotFound!=indexFound){
      return;
    }
  }
  
  NSURL *url = [NSURL URLWithString:urlPath];
  NSURLRequest *request = nil;
  NSURLRequestCachePolicy cachePolicy = self.urlCacheStoragePolicy;
  NSTimeInterval timeout = self.connectionTimeout;
  if (self.httpHeaders) {
    NSMutableURLRequest *r = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:cachePolicy timeoutInterval:timeout];
    for (NSString *key in self.httpHeaders) {
      [r addValue:[self.httpHeaders valueForKey:key] forHTTPHeaderField:key];
    }
    request = r;
  }else{
    request = [NSURLRequest requestWithURL:url cachePolicy:cachePolicy timeoutInterval:timeout];
  }
  
  [self _addRequestId:&request];
  if (request){
    [_loadingQueue addObject:request];
    [_requestCompletions setObject:[completionWithDownloadedData copy] forKey:request.requestId];
    [self launchNextConnection];
  }
}

- (void)queueURLRequest:(NSURLRequest *)urlRequest completion:(void (^)(NSData *))completionWithDownloadedData
{
  [self _addRequestId:&urlRequest];
  
  [_loadingQueue addObject:[urlRequest copy] ];
  [_requestCompletions setObject:[completionWithDownloadedData copy] forKey:urlRequest.requestId];
  [self launchNextConnection];
}

- (void)jsonWithRequest:(NSURLRequest *)jsonRequest options:(NSJSONWritingOptions)options
             completion:(void (^)(id))completionWithJSONObject
{
  [self queueURLRequest:jsonRequest
             completion:^(NSData *data) {
               if (data == nil) {
                 completionWithJSONObject(nil);
                 return;
               }
               
               NSError *error = nil;
               id jsonObject  = [NSJSONSerialization JSONObjectWithData:data
                                                                options:options error:&error];
               if (error) {
                 if (onNetworkError) {
                   onNetworkError(error);
                   completionWithJSONObject(nil);
                   return;
                 }
               }
               
               completionWithJSONObject(jsonObject);
               
             }];
}

- (void)imageWithPath:(NSString *)urlPath completion:(void (^)(UIImage *, BOOL))completionWithImageYesIfFromCache
{
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlPath]];
  NSData *data = [_dataCache objectForKey:request.requestId];
  if  (data.length > 0){
    UIImage *image = [UIImage imageWithData:data];
    completionWithImageYesIfFromCache(image, YES);
  }else {
    [self queueRequest:urlPath completion:^(NSData *data) {
      UIImage *image = [UIImage imageWithData:data];
      completionWithImageYesIfFromCache(image, NO);
    }];
  }
}

- (void)dequeueWithPath:(NSString *)path
{
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:path]];
  NSString *key = request.requestId;
  NSArray * searchResults = [_currentConnections filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    BDURLConnection *aConn = evaluatedObject;
    return [aConn.originalRequest.requestId isEqualToString:key];
  }]];
  
  if (searchResults.count > 0) {
    BDURLConnection *connection = [searchResults objectAtIndex:0];
    [connection cancel];
    [self _removeConnection:connection];
    
  }
}

- (void)clearCache
{
  [_dataCache removeAllObjects];
}

- (void)clearQueue
{
  
  //DLog(@"clear queue.");
  for (NSURLConnection *conn in _currentConnections) {
    
    if (self.onNetworkActivity) {
      self.onNetworkActivity(NO);
    }
    
    [conn cancel];
  }
  [_currentConnections removeAllObjects];
  [_loadingQueue removeAllObjects];
  [_requestCompletions removeAllObjects];
  [_currentConnectionsData removeAllObjects];
}

- (NSUInteger)numberOfItemsInQueue
{
  return _loadingQueue.count;
}

- (void)launchNextConnection
{
  //DLog(@"launchNextConnection…");
  if  (self.pause){
    return;
  }
  
  if (_currentConnections.count >= self.maximumNumberOfThreads) {
    //        DLog(@"Threads at Max. Abort.");
    return;
  }
  
  if (self.numberOfItemsInQueue==0) {
    //        DLog(@"Nothing in queue.");
    return;
  }
  
  //    DLog(@"still in queue: %d", self.numberOfItemsInQueue);
  
  NSURLRequest *request = [_loadingQueue objectAtIndex:0];
  [_loadingQueue removeObjectAtIndex:0];
  
  NSString *requestKey = request.requestId;
  NSData *dataInCache = [_dataCache objectForKey:requestKey];
  if (dataInCache) {
    void (^completion)(NSData*) = [_requestCompletions objectForKey:requestKey];
    [_requestCompletions removeObjectForKey:requestKey];
    if (completion) {
      completion(dataInCache);
    }
    return;
  }
  
  BDURLConnection *conn = [[BDURLConnection alloc] initWithRequest:request delegate:self];
  conn.originalRequest = request;
  conn.suggestedFilename = request.URL.lastPathComponent;
  [_currentConnections addObject:conn];
  
  void (^completion)(NSData*) = [_requestCompletions objectForKey:requestKey];
  [conn setCompletionWithDownloadedData:completion];
  [conn start];
  if (self.onNetworkActivity) {
    self.onNetworkActivity(YES);
  }
}

- (NSUInteger)cacheSizeLimit{
  return _dataCache.totalCostLimit;
}

- (void)setCacheSizeLimit:(NSUInteger)cacheSizeLimit
{
  [_dataCache setCountLimit:cacheSizeLimit];
}

#pragma mark - connection delegate
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
  NSMutableData *data = [[NSMutableData alloc] init];
  [_currentConnectionsData setObject:data forKey:connection];
  
  BDURLConnection *conn = (BDURLConnection*) connection;
  [conn setMIMEType:response.MIMEType];
  [conn setExpectedLength:response.expectedContentLength];
  [conn setProgress:0.0];
  [conn setSuggestedFilename:response.suggestedFilename];
  
  if (self.onDownloadProgressWithProgressAndSuggestedFilename) {
    self.onDownloadProgressWithProgressAndSuggestedFilename(conn.progress, conn.suggestedFilename);
  }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  NSMutableData *_data = (NSMutableData*)[_currentConnectionsData objectForKey:connection];
  [_data appendData:data];
  BDURLConnection *conn = (BDURLConnection*) connection;
  [conn setProgress:_data.length/(double) conn.expectedLength ];
  if (self.onDownloadProgressWithProgressAndSuggestedFilename) {
    self.onDownloadProgressWithProgressAndSuggestedFilename(conn.progress, conn.suggestedFilename);
  }
}

- (void)_removeConnection:(BDURLConnection*)conn
{
  
  __block NSUInteger indexToRemove = NSNotFound;
  [_loadingQueue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSURLRequest *req = obj;
    if  ([req.URL.absoluteString isEqualToString:conn.originalRequest.URL.absoluteString]){
      indexToRemove = idx;
      *stop = YES;
    }
  }];
  
  
  
  if (indexToRemove!=NSNotFound) {
    [_loadingQueue removeObjectAtIndex:indexToRemove];
  }
  
  [_currentConnections removeObject:conn];
  [_currentConnectionsData removeObjectForKey:conn];
  [_requestCompletions removeObjectForKey:conn];
  
  
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  if (self.onNetworkActivity) {
    self.onNetworkActivity(NO);
  }
  
  NSData *data = [_currentConnectionsData objectForKey:connection];
  BDURLConnection *conn = (BDURLConnection*) connection;
  NSString *requestKey = conn.originalRequest.requestId;
  if (data.length > 0){
    [_dataCache setObject:data forKey:requestKey cost:data.length];
  }
  [self _removeConnection:conn];
  
  void(^completion)(NSData*) = [(BDURLConnection*)connection completionWithDownloadedData];
  
  if (completion) {
    completion(data);
  }
  
  [self launchNextConnection];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
  
  if (self.onNetworkActivity){
    self.onNetworkActivity(NO);
  }
  
  [self _removeConnection:(BDURLConnection*)connection];
  if ([error.domain isEqualToString:NSURLErrorDomain] ) {
    //        [self clearQueue];
    if (self.onNetworkError) {
      self.onNetworkError(error);
    }
  }
  
  void(^completion)(NSData*) = [(BDURLConnection*)connection completionWithDownloadedData];
  if  (completion){
    completion(nil);
  }
  
  [self launchNextConnection];
  NSLog(@"%@", error);
  
}

- (id)init
{
  self = [super init];
  if (self) {
    self.maximumNumberOfThreads = kMaxNumberOfThreads;
    self.urlCacheStoragePolicy = NSURLCacheStorageAllowedInMemoryOnly;
    _currentConnections = [[NSMutableArray alloc] init];
    _currentConnectionsData = [[NSMutableDictionary alloc] init];
    _loadingQueue = [[NSMutableArray alloc] init];
    _requestCompletions = [[NSMutableDictionary alloc] init];
    _dataCache = [[NSCache alloc] init];
    self.completionQueue = NULL;
    [_dataCache setName:@"data cache"];
    [_dataCache setCountLimit:kMaxCache];
    self.connectionTimeout = kIntervalDefaultTimeout;
    
    requestId = 100;
  }
  return self;
}

#pragma mark - queue manipulation
- (void)setPause:(BOOL)pause
{
  if (_pause==pause) {
    return;
  }
  
  _pause = pause;
  if (!_pause) {
    [self launchNextConnection];
  }
}

- (NSArray *)_removePendingRequestsAndCompletions
{
  self.pause = YES;
  NSArray *result = [NSArray array];
  for (BDURLConnection *conn in _currentConnections) {
    NSURLRequest *req = conn.originalRequest;
    if (req) {
      id completion = [_requestCompletions objectForKey:conn.originalRequest.requestId];
      
      NSDictionary *requestAndCompletion = [NSDictionary dictionaryWithObjectsAndKeys:
                                            req, BDMDKeyRequest,
                                            completion, BDMDKeyCompletion,
                                            nil];
      result = [result arrayByAddingObject:requestAndCompletion];
    }
  }
  [self clearQueue];
  self.pause = NO;
  return result;
}

- (void)_queueRequestsWithCompletions:(NSArray*)requestsAndCompletions
{
  for (NSDictionary * info in requestsAndCompletions){
    NSURLRequest *r = [info objectForKey:BDMDKeyRequest];
    void(^completion)(NSData*) = [info objectForKey:BDMDKeyCompletion];
    [self queueURLRequest:r completion:completion];
  }
}

#pragma mark - singleton

+ (BDMultiDownloader *)shared
{
  static dispatch_once_t once;
  static BDMultiDownloader * singleton;
  dispatch_once(&once, ^ { singleton = [[BDMultiDownloader alloc] init]; });
  return singleton;
}

#pragma mark - synthesize

@synthesize onNetworkActivity;
@synthesize onDownloadProgressWithProgressAndSuggestedFilename;
@synthesize onNetworkError;
@synthesize onDuplicateDownload;

@synthesize maximumNumberOfThreads;
@synthesize httpHeaders;
@synthesize cacheSizeLimit=_cacheSizeLimit;
@synthesize connectionTimeout;

@synthesize completionQueue;
@synthesize urlCacheStoragePolicy;
@synthesize pause=_pause;
@end
