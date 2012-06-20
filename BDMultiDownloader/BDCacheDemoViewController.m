//
//  BDCacheDemoViewController.m
//  BDMultiDownloader
//
//  Created by Nor Oh on 6/18/12.
//  Copyright (c) 2012 Bluedot. All rights reserved.
//

#import "BDCacheDemoViewController.h"
#import "BDMultiDownloader.h"
#define kPathImage1 @"http://farm8.staticflickr.com/7085/7383444834_7dd747e70a_o.jpg"
#define kPathImage2 @"http://farm8.staticflickr.com/7099/7383512334_e4b1d03bfb_o.jpg"

@interface BDCacheDemoViewController ()

@end

@implementation BDCacheDemoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Cache Demo";
    }
    return self;
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    self.progressBar = nil;
    self.progressBar2 = nil;
    self.imageView = nil;
    self.imageView2 = nil;
    self.startButton = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //configure the BDMutliDownloader to update the progressView
    [BDMultiDownloader shared].onDownloadProgressWithProgressAndSuggestedFilename = ^(double progress, NSString *filename){
        if ([[kPathImage1 lastPathComponent] isEqualToString:filename]) {
            [self.progressBar setProgress:progress animated:YES];
        }else{
            [self.progressBar2 setProgress:progress animated:YES];
        }
    };
}

- (void)didPressStart:(id)sender
{
    //reset all images and UIProgressViews
    self.startButton.enabled = NO;
    self.progressBar.progress = 0;
    self.progressBar2.progress = 0;
    self.imageView.image = nil;
    self.imageView2.image = nil;
    
    
    //launch downloading of large images 
    [[BDMultiDownloader shared] imageWithPath:kPathImage1
                                   completion:^(UIImage * image, BOOL fromCache) {
                                       self.imageView.image = image;
                                       if (self.imageView2.image!=nil) {
                                           self.startButton.enabled = YES;
                                       }
                                       NSLog(@"Image 1 is from cache: %@", fromCache?@"YES":@"NO");
                                   }];
    
    [[BDMultiDownloader shared] imageWithPath:kPathImage2
                                   completion:^(UIImage * image, BOOL fromCache) {
                                       self.imageView2.image = image;
                                       if (self.imageView.image!=nil) {
                                           self.startButton.enabled = YES;
                                       }
                                       NSLog(@"Image 2 is from cache: %@", fromCache?@"YES":@"NO");
                                   }];
    
    //Notice that the first time you hit Start, you can see the progress bar
    //running as the downloading proceeds. 
    //However, the second time, the images are loaded instantly. 
    //This is because BDMultiDownloader returns images from the cache.
    
}

- (void)didCancel:(id)sender
{
    
    //Cancel all requests at once. 
    //This is how you kill all BDMultiDownloader opearations. 
    [[BDMultiDownloader shared] clearQueue];
    self.startButton.enabled = YES;
}

- (void)didStop1:(id)sender
{
    //This demonstates how to cancel an ongoing downloading.
    //This only works while the download hasn't finished, apparently.
    [[BDMultiDownloader shared] dequeueWithPath:kPathImage1];
}

- (void)didStop2:(id)sender
{
    [[BDMultiDownloader shared] dequeueWithPath:kPathImage2];    
}

@synthesize startButton;
@synthesize imageView2;
@synthesize progressBar;
@synthesize imageView;
@synthesize progressBar2;
@end
