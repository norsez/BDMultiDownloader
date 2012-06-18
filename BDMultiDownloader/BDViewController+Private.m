//
//  BDViewController+Private.m
//  BDMultiDownloader
//
//  Created by Nor Oh on 6/18/12.
//  Copyright (c) 2012 Bluedot. All rights reserved.
//

#import "BDViewController+Private.h"

@implementation BDViewController (Private)
-(NSArray*)_extractAlbumsWithJSON:(NSDictionary*)JSON
{
    NSArray *albums = [NSArray array];
    NSArray *entries = [JSON valueForKeyPath:@"feed.entry"];
    for (NSDictionary * entry in entries) {
        NSArray * imageLinks = [entry valueForKey:@"im:image"];
        NSDictionary *imageLink = nil;
        int size = 0;
        for (NSDictionary *link in imageLinks) {
            //want the largest image size
            if (size < [(NSString*)[link valueForKeyPath:@"attributes.height"] intValue]) {
                imageLink = link;
            }
        }
        
        NSMutableDictionary * anAlbum = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  [entry valueForKeyPath:@"im:name.label"], kvTitle,
                                  [imageLink valueForKey:@"label"] ,kvImageLink,
                                  nil];
        albums = [albums arrayByAddingObject:anAlbum];
    }
    return albums;
}

- (BOOL)_isIndexPathVisible:(NSIndexPath *)indexPath
{
    NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
    return [visibleIndexPaths containsObject:indexPath];
}

- (UIBarButtonItem *)_clearBarButton
{
    UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                                                    style:UIBarButtonItemStyleDone target:self action:@selector(clearItems)];
    return clearButton;
}

@end
