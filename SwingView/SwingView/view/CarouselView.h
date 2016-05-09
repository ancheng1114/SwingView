//
//  CarouselView.h
//  SwingView
//
//  Created by AnCheng on 4/30/16.
//  Copyright © 2016 AnCheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

@interface CarouselView : UIView

@property (nonatomic ,strong) iCarousel *carousel1;
@property (nonatomic ,strong) iCarousel *carousel2;

@property (nonatomic ,strong) UIProgressView *progress1;
@property (nonatomic ,strong) UIProgressView *progress2;

@property (nonatomic ,strong) UIButton *resizeBtn;

@property (nonatomic ,strong) NSLayoutConstraint *carouselWidth;
@property (nonatomic ,strong) NSLayoutConstraint *progress2Leading;
@property (nonatomic ,strong) NSLayoutConstraint *progress2Bottom;

@property (nonatomic) BOOL isHalf;

- (void)setMode:(PANAL_TYPE)mode;
- (void)setDelegate:(id)delegate;
- (void)reloadView;

- (void)setProgress:(float)progress view:(BOOL)isFirst;

@end
