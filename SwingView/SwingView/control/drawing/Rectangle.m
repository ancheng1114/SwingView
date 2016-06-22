//
//  Rectangle.m
//  GolfChannel
//
//  Created by AnCheng on 3/25/15.
//  Copyright (c) 2015 ancheng1114. All rights reserved.
//

#import "Rectangle.h"
#include "CGUtils.h"

@implementation Rectangle

- (id)init
{
    self = [super init];
    if (self) {
        self.shapeType = DRAWING_TOOL_RECTANGLE;
        self.centerPt = CGPointZero;
        self.startPt = CGPointZero;
        self.endPt = CGPointZero;
        
        self.shapeEditMode = EDIT_MODE_CENTER_PT;

    }
    
    return self;
}

- (float)distanceFromPt:(CGPoint)pt
{
    CGFloat distance1 = distanceFromPointToLine(pt, self.startPt, self.centerPt);
    CGFloat distance2 = distanceFromPointToLine(pt, self.endPt, self.centerPt);
    CGFloat distance = MIN(distance1, distance2);
    
    if (distance > kDistanceLimit)
        distance = FLT_MAX;
    
    return distance;
}

- (BOOL)IsTappedDeleteCtrlPt:(CGPoint)pt
{
    return isEqualPoint(self.centerPt, pt, kCtrlPtRadius);
}

@end
