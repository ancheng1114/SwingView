//
//  AutoLine.m
//  SwingView
//
//  Created by AnCheng on 6/1/16.
//  Copyright © 2016 AnCheng. All rights reserved.
//

#import "AutoLine.h"
#include "CGUtils.h"

@implementation AutoLine

- (id)init
{
    self = [super init];
    if (self)
    {
        self.shapeType = DRAWING_TOOL_AUTOLINE;
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
