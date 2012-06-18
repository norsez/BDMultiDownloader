//
//  BDViewController+Private.h
//  BDMultiDownloader
//
//  Created by Nor Oh on 6/18/12.
//  Copyright (c) 2012 Bluedot. All rights reserved.
//

#import "BDViewController.h"

#define kvImageLink @"image"
#define kvTitle @"title"
#define kvLoadedImage @"loadedImage"

@interface BDViewController (Private)
- (NSArray*)_extractAlbumsWithJSON:(NSDictionary*)JSON;
- (BOOL)_isIndexPathVisible:(NSIndexPath*)indexPath;
- (UIBarButtonItem*)_clearBarButton;
@end
