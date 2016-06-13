//
//  CustomShape.m
//  SwingView
//
//  Created by AnCheng on 6/12/16.
//  Copyright © 2016 AnCheng. All rights reserved.
//

#import "CustomShape.h"
#include "CGUtils.h"

@implementation CustomShape

- (id)init
{
    self = [super init];
    if (self)
    {
        self.shapeType = DRAWING_TOOL_BLANCEBOX;
        self.centerPt = CGPointZero;
        self.radius = 0.0f;
    }
    
    return self;
}

- (float)distanceFromPt:(CGPoint)pt
{
    CGFloat distance = distanceBetween2Points(self.centerPt, pt);
    if (distance > self.radius + kDistanceLimit)
        return FLT_MAX;
    
    return distance;
}

- (BOOL)IsTappedDeleteCtrlPt:(CGPoint)pt
{
    return isEqualPoint(self.centerPt, pt, kCtrlPtRadius);
}

@end
