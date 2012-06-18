//
//  BDViewController.m
//  BDMultiDownloader
//
//  Created by Nor Oh on 6/18/12.
//  Copyright (c) 2012 Bluedot. All rights reserved.
//

#import "BDViewController.h"
#import "BDMultiDownloader.h"
#import "BDViewController+Private.h"
#define kURLiTunesRSS @"http://itunes.apple.com/us/rss/topalbums/limit=300/explicit=true/json"

@interface BDViewController ()
{
    NSArray *_albums;
}

- (void) initializeData;

@end

@implementation BDViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"MultiDownload Demo";
    }
    return self;
}

- (void)initializeData
{
    //BDMutliDownloader downloads data from remote site.
    [[BDMultiDownloader shared] 
     queueRequest:kURLiTunesRSS 
     completion:^(NSData *data) {
         NSDictionary * chartJSON = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:0
                                                                      error:nil];
         _albums = [self _extractAlbumsWithJSON:chartJSON];
         [self.tableView reloadData];
     }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _albums = [[NSArray alloc] init];
    
    
    //configure the block for downloading progress
    [BDMultiDownloader shared].onDownloadProgressWithProgressAndSuggestedFilename = ^(double progress, NSString* file){
        NSLog(@"%d %%  %@", (int)(progress * 100), file);  
    };
    
    
       
    [self initializeData];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _albums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewScrollPositionNone;
    }
    
    NSMutableDictionary *album = [_albums objectAtIndex:indexPath.row];
    cell.textLabel.text = [album valueForKey:kvTitle];
    cell.imageView.image = nil;
    
    //Here's a pattern for updating table cells with data:
    
    if ([album valueForKey:kvLoadedImage]!=nil) {
        //if the datasource item is already loaded, just update the cell and return.
        cell.imageView.image = [album valueForKey:kvLoadedImage];
    }else{
        //if the data needs to be downloaded, do it.
        //here's using the convenient method for loading images
        [[BDMultiDownloader shared] imageWithPath:[album valueForKey:kvImageLink]
                                       completion:^(UIImage *image, BOOL fromCache) {
                                           //save downloaded image to the datasource item.
                                           [album setValue:image forKey:kvLoadedImage];
                                           
                                           //animate the newly loaded image on the table view.
                                           //and animate only if the image is not from cache (first loaded.)
                                           UITableViewRowAnimation animation = fromCache?UITableViewScrollPositionNone:UITableViewRowAnimationAutomatic;
                                           if ([self _isIndexPathVisible:indexPath]) {    
                                               [self.tableView canCancelContentTouches];
                                               [self.tableView beginUpdates];
                                               [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                                                     withRowAnimation:animation];
                                               [self.tableView endUpdates];
                                           }
                                       }];
    }
    
    
    return cell;
}

@end
