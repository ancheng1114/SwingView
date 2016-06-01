//
//  SwingToolView.h
//  SwingView
//
//  Created by AnCheng on 4/18/16.
//  Copyright © 2016 AnCheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SwingToolView : UIView


@property (nonatomic ,assign) IBOutlet UIButton *rectangleBtn;
@property (nonatomic ,assign) IBOutlet UIButton *circleBtn;
@property (nonatomic ,assign) IBOutlet UIButton *lineBtn;
@property (nonatomic ,assign) IBOutlet UIButton *freelineBtn;
@property (nonatomic ,assign) IBOutlet UIButton *angleBtn;
@property (nonatomic ,assign) IBOutlet UIButton *blastBtn;
@property (nonatomic ,assign) IBOutlet UIButton *autolineBtn;

- (void)setColorPanel:(DRAWING_COLOR)color;


@end
