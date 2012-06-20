//
//  BDCacheDemoViewController.h
//  BDMultiDownloader
//
//  Created by Nor Oh on 6/18/12.
//  Copyright (c) 2012 Bluedot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BDCacheDemoViewController : UIViewController
@property (nonatomic, strong) IBOutlet UIImageView* imageView;
@property (nonatomic, strong) IBOutlet  UIProgressView* progressBar;
@property (nonatomic, strong) IBOutlet UIImageView* imageView2;
@property (nonatomic, strong) IBOutlet UIButton* startButton;
@property (nonatomic, strong) IBOutlet UIProgressView* progressBar2;

- (IBAction)didPressStart:(id)sender;
- (IBAction)didCancel:(id)sender;
- (IBAction)didStop1:(id)sender;
- (IBAction)didStop2:(id)sender;
@end
