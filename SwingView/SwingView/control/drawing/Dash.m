//
//  Dash.m
//  GolfChannel
//
//  Created by AnCheng on 3/25/15.
//  Copyright (c) 2015 ancheng1114. All rights reserved.
//

#import "Dash.h"
#include "CGUtils.h"

@implementation Dash

- (id)init
{
    self = [super init];
    if (self)
    {
        self.shapeType = DRAWING_TOOL_DASH;
        self.startPt = CGPointZero;
        self.endPt = CGPointZero;
    }
    
    return self;
}

- (float)distanceFromPt:(CGPoint)pt
{
    CGFloat distance = distanceFromPointToLine(pt, self.startPt, self.endPt);
    
    if (distance > kDistanceLimit)
    {
        distance = FLT_MAX;
    } else if ((self.startPt.x - kDistanceLimit > pt.x || pt.x > self.endPt.x + kDistanceLimit) || (self.startPt.y - kDistanceLimit > pt.y || pt.y > self.endPt.y + kDistanceLimit)) {
       // distance = FLT_MAX;
    }
    
    return distance;
}

- (BOOL)IsTappedDeleteCtrlPt:(CGPoint)pt
{
    return isEqualPoint(self.startPt, pt, kCtrlPtRadius);
}

@end
