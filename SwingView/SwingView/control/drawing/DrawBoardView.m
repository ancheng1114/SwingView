//
//  DrawBoardView.m
//  DrawTest
//
//  Created by xiangmi on 5/25/13.
//  Copyright (c) 2013 xiangmi. All rights reserved.
//

#import "DrawBoardView.h"
#include "CGUtils.h"
#import "Circle.h"
#import "Line.h"
#import "Angle.h"
#import "FreeDraw.h"
#import "Dash.h"
#import "Rectangle.h"
#import "CustomShape.h"

#define kLineWidth          2.0f

@implementation DrawBoardView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    
    return self;
}

- (void)dealloc
{
    [mCtrlLayer removeFromSuperlayer];
    [mShapeList removeAllObjects];
}

- (void)initialize
{
    self.userInteractionEnabled = YES;
    self.backgroundColor = [UIColor clearColor];
    
    mShapeList = [[NSMutableArray alloc] init];
    
    mFirstPt = mLastPt = CGPointZero;
    mCandShape = mTempShape = nil;
    
    mShapeType = 0;
    mEditMode = EDIT_MODE_NONE;
    mTempIsCandi = NO;
    mIsDeletable = NO;
    
    [self setShapeColor:DRAWING_COLOR_RED];
    [self setShapeType:DRAWING_TOOL_LINE];

}

- (void)setupCtrlLayer:(id)delegate
{
    mCtrlLayer = [[CALayer alloc] init];
    mCtrlLayer.frame = self.frame;
    mCtrlLayer.backgroundColor = [UIColor clearColor].CGColor;
    mCtrlLayer.delegate = delegate;
    [self.layer addSublayer:mCtrlLayer];
    
    [mCtrlLayer setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self drawShapesOnBoard:context];
    if (!mCtrlLayer)
        [self drawShapeCtrlsOnBoard:context];
}

#pragma mark - Draw
- (void)setNeedsDisplay
{
    [mCtrlLayer setNeedsDisplay];
    [super setNeedsDisplay];
}

- (void)drawDeletableMark:(CGContextRef)context atPoint:(CGPoint)pt
{
	CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    
    CGFloat halfRadius = kCtrlPtRadius * 1.5 / 2.0f;
    
    CGContextAddArc(context, pt.x, pt.y, kCtrlPtRadius * 1.5, 0.0f, M_PI * 2.0f, 0);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    CGContextMoveToPoint(context, pt.x - halfRadius, pt.y - halfRadius);
    CGContextAddLineToPoint(context, pt.x + halfRadius, pt.y + halfRadius);
    
    CGContextMoveToPoint(context, pt.x - halfRadius, pt.y + halfRadius);
    CGContextAddLineToPoint(context, pt.x + halfRadius, pt.y - halfRadius);
    
    CGContextStrokePath(context);
}

- (void)drawCircle:(CGContextRef)context withCircle:(Circle *)aCircle
{
    CGContextSetStrokeColorWithColor(context, aCircle.shapeColor.CGColor);
    
    CGFloat centerPtX = [self changeAbsolute:aCircle.centerPt.x];
    CGFloat centerPtY = [self changeAbsolute:aCircle.centerPt.y];
    CGFloat radius = [self changeAbsolute:aCircle.radius];
    
    CGContextAddArc(context, centerPtX, centerPtY, radius, 0.0f, M_PI * 2.0f, 0);
    CGContextStrokePath(context);
}

- (void)drawCircleCtrl:(CGContextRef)context withCircle:(Circle *)aCircle
{
	CGContextSetStrokeColorWithColor(context, aCircle.shapeColor.CGColor);
    
    if (mIsDeletable)
    {
        [self drawDeletableMark:context atPoint:aCircle.centerPt];

    } else {
        if (aCircle.isCandi)
        {
            CGFloat centerPtX = [self changeAbsolute:aCircle.centerPt.x];
            CGFloat centerPtY = [self changeAbsolute:aCircle.centerPt.y];
            CGFloat radius = [self changeAbsolute:aCircle.radius];
            
            CGContextAddArc(context, centerPtX, centerPtY, kCtrlPtRadius, 0.0f, M_PI * 2.0f, 0);
            CGContextDrawPath(context, kCGPathFillStroke);
            
            CGContextAddArc(context, centerPtX, centerPtY + radius, kCtrlPtRadius, 0.0f, M_PI * 2.0f, 0);
            CGContextDrawPath(context, kCGPathFillStroke);
        }
    }
}

- (void)drawLine:(CGContextRef)context withLine:(Line *)aLine
{
    CGContextSetStrokeColorWithColor(context, aLine.shapeColor.CGColor);
    
    CGFloat startPtX = [self changeAbsolute:aLine.startPt.x];
    CGFloat startPtY = [self changeAbsolute:aLine.startPt.y];
    
    CGFloat endPtX = [self changeAbsolute:aLine.endPt.x];
    CGFloat endPtY = [self changeAbsolute:aLine.endPt.y];
    
    CGContextMoveToPoint(context, startPtX, startPtY);
    CGContextAddLineToPoint(context, endPtX, endPtY);
    CGContextStrokePath(context);
}

- (void)drawLineCtrl:(CGContextRef)context withLine:(Line *)aLine
{
	CGContextSetStrokeColorWithColor(context, aLine.shapeColor.CGColor);
    
    if (mIsDeletable)
    {
        [self drawDeletableMark:context atPoint:aLine.startPt];
    } else {
        if (aLine.isCandi)
        {
            CGFloat startPtX = [self changeAbsolute:aLine.startPt.x];
            CGFloat startPtY = [self changeAbsolute:aLine.startPt.y];
            
            CGFloat endPtX = [self changeAbsolute:aLine.endPt.x];
            CGFloat endPtY = [self changeAbsolute:aLine.endPt.y];
            
            CGContextAddArc(context, startPtX, startPtY, kCtrlPtRadius, 0.0f, M_PI * 2.0f, 0);
            CGContextDrawPath(context, kCGPathFillStroke);
            
            CGContextAddArc(context, endPtX, endPtY, kCtrlPtRadius, 0.0f, M_PI * 2.0f, 0);
            CGContextDrawPath(context, kCGPathFillStroke);
        }
    }
}

- (void)drawRectangle:(CGContextRef)context withRectangle:(Rectangle *)aRectangle
{
    float radiusY = fabs(aRectangle.centerPt.y - aRectangle.startPt.y);
    float radiusX = fabs(aRectangle.centerPt.x - aRectangle.endPt.x);
    
    CGContextSetStrokeColorWithColor(context, aRectangle.shapeColor.CGColor);
    
    radiusY = [self changeAbsolute:radiusY];
    radiusX = [self changeAbsolute:radiusX];

    CGFloat centerPtX = [self changeAbsolute:aRectangle.centerPt.x];
    CGFloat centerPtY = [self changeAbsolute:aRectangle.centerPt.y];
    
    CGContextMoveToPoint(context, centerPtX - radiusX, centerPtY + radiusY);
    CGContextAddLineToPoint(context, centerPtX - radiusX, centerPtY - radiusY);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, centerPtX - radiusX, centerPtY - radiusY);
    CGContextAddLineToPoint(context, centerPtX + radiusX, centerPtY - radiusY);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, centerPtX + radiusX, centerPtY + radiusY);
    CGContextAddLineToPoint(context, centerPtX + radiusX, centerPtY - radiusY);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, centerPtX - radiusX, centerPtY + radiusY);
    CGContextAddLineToPoint(context, centerPtX + radiusX, centerPtY + radiusY);
    CGContextStrokePath(context);
    
    CGContextStrokePath(context);
}

- (void)drawRectangleCtrl:(CGContextRef)context withRectangle:(Rectangle *)aRectangle
{
    CGContextSetStrokeColorWithColor(context, aRectangle.shapeColor.CGColor);
    
    if (mIsDeletable)
    {
        [self drawDeletableMark:context atPoint:aRectangle.centerPt];
    } else {
        if (aRectangle.isCandi)
        {
            
            CGFloat startPtX = [self changeAbsolute:aRectangle.startPt.x];
            CGFloat startPtY = [self changeAbsolute:aRectangle.startPt.y];
            
            CGFloat endPtX = [self changeAbsolute:aRectangle.endPt.x];
            CGFloat endPtY = [self changeAbsolute:aRectangle.endPt.y];
            
            CGFloat centerPtX = [self changeAbsolute:aRectangle.centerPt.x];
            CGFloat centerPtY = [self changeAbsolute:aRectangle.centerPt.y];
            
            CGContextAddArc(context, centerPtX, centerPtY, kCtrlPtRadius, 0.0f, M_PI * 2.0f, 0);
            CGContextDrawPath(context, kCGPathFillStroke);
            
            CGContextAddArc(context, startPtX, startPtY, kCtrlPtRadius, 0.0f, M_PI * 2.0f, 0);
            CGContextDrawPath(context, kCGPathFillStroke);
            
            CGContextAddArc(context, endPtX, endPtY, kCtrlPtRadius, 0.0f, M_PI * 2.0f, 0);
            CGContextDrawPath(context, kCGPathFillStroke);
            
        }
    }
}

- (void)drawDashCtrl:(CGContextRef)context withLine:(Dash *)aLine
{
    CGContextSetStrokeColorWithColor(context, aLine.shapeColor.CGColor);
    
    if (mIsDeletable)
    {
        [self drawDeletableMark:context atPoint:aLine.startPt];
    } else {
        if (aLine.isCandi)
        {
            CGContextAddArc(context, aLine.startPt.x, aLine.startPt.y, kCtrlPtRadius, 0.0f, M_PI * 2.0f, 0);
            CGContextDrawPath(context, kCGPathFillStroke);
            
            CGContextAddArc(context, aLine.endPt.x, aLine.endPt.y, kCtrlPtRadius, 0.0f, M_PI * 2.0f, 0);
            CGContextDrawPath(context, kCGPathFillStroke);
        }
    }
}

- (void)drawDash:(CGContextRef)context withLine:(Dash *)aLine
{
    CGContextSetStrokeColorWithColor(context, aLine.shapeColor.CGColor);
    
    CGFloat dashes[] = {5 ,3};
    CGContextSetLineDash(context, 1.0, dashes, 2);
    
    CGContextMoveToPoint(context, aLine.startPt.x, aLine.startPt.y);
    CGContextAddLineToPoint(context, aLine.endPt.x, aLine.endPt.y);
    
    CGContextStrokePath(context);

    CGContextSetLineDash(context, 0, nil, 0);
    
}

- (void)drawText:(CGContextRef)context atPosition:(CGPoint)pt withString:(NSString *)strText withColor:(UIColor *)textColor
{
	CGContextSetStrokeColorWithColor(context, textColor.CGColor);
    CGContextSetFillColorWithColor(context, textColor.CGColor);
    
    //UIFont *font = [UIFont fontWithName:@"Helvetica-Bold" size:18.0f];
    //[strText drawAtPoint:pt withFont:font];
    NSDictionary *textAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:18.0]};
    [strText drawAtPoint:pt withAttributes:textAttributes];
    
    CGContextSetFillColorWithColor(context, [UIColor darkGrayColor].CGColor);
}

- (void)drawAngleCtrl:(CGContextRef)context withAngle:(Angle *)aAngle
{
	CGContextSetStrokeColorWithColor(context, aAngle.shapeColor.CGColor);
    
    if (mIsDeletable)
    {
        [self drawDeletableMark:context atPoint:aAngle.centerPt];
    } else {
        if (aAngle.isCandi)
        {
            
            CGFloat startPtX = [self changeAbsolute:aAngle.startPt.x];
            CGFloat startPtY = [self changeAbsolute:aAngle.startPt.y];
            
            CGFloat endPtX = [self changeAbsolute:aAngle.endPt.x];
            CGFloat endPtY = [self changeAbsolute:aAngle.endPt.y];
            
            CGFloat centerPtX = [self changeAbsolute:aAngle.centerPt.x];
            CGFloat centerPtY = [self changeAbsolute:aAngle.centerPt.y];

            CGContextAddArc(context, startPtX, startPtY, kCtrlPtRadius, 0.0f, M_PI * 2.0f, 0);
            CGContextDrawPath(context, kCGPathFillStroke);
            
            CGContextAddArc(context, endPtX, endPtY, kCtrlPtRadius, 0.0f, M_PI * 2.0f, 0);
            CGContextDrawPath(context, kCGPathFillStroke);
            
            CGContextAddArc(context, centerPtX, centerPtY, kCtrlPtRadius, 0.0f, M_PI * 2.0f, 0);
            CGContextDrawPath(context, kCGPathFillStroke);
        }
    }
}

- (void)drawAngle:(CGContextRef)context withAngle:(Angle *)aAngle
{
	CGContextSetStrokeColorWithColor(context, aAngle.shapeColor.CGColor);
    
    CGFloat startPtX = [self changeAbsolute:aAngle.startPt.x];
    CGFloat startPtY = [self changeAbsolute:aAngle.startPt.y];
    
    CGFloat endPtX = [self changeAbsolute:aAngle.endPt.x];
    CGFloat endPtY = [self changeAbsolute:aAngle.endPt.y];
    
    CGFloat centerPtX = [self changeAbsolute:aAngle.centerPt.x];
    CGFloat centerPtY = [self changeAbsolute:aAngle.centerPt.y];

    CGContextMoveToPoint(context, startPtX, startPtY);
    CGContextAddLineToPoint(context, centerPtX, centerPtY);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, endPtX, endPtY);
    CGContextAddLineToPoint(context, centerPtX, centerPtY);
    CGContextStrokePath(context);
    
    NSString *angleString = [NSString stringWithFormat:@"%d.%d˚", aAngle.valueMul10 / 10,  aAngle.valueMul10 % 10];
    [self drawText:context atPosition:CGPointMake(centerPtX + 20 ,centerPtY - 10.0f) withString:angleString withColor:aAngle.shapeColor];
}

- (void)drawFreeDrawCtrl:(CGContextRef)context withFreeDraw:(FreeDraw *)aFreedraw
{
	CGContextSetStrokeColorWithColor(context, aFreedraw.shapeColor.CGColor);
    
    if (mIsDeletable)
    {
        CGPoint pt = [aFreedraw pointAtIndex:0];
        [self drawDeletableMark:context atPoint:pt];
    }
}

- (void)drawFreeDraw:(CGContextRef)context withFreeDraw:(FreeDraw *)aFreedraw
{
    int pointCount = [aFreedraw pointCount];
    if (pointCount < 2)
        return;
    
	CGContextSetStrokeColorWithColor(context, aFreedraw.shapeColor.CGColor);
    
    CGPoint pt = [aFreedraw pointAtIndex:0];
    pt = [self absoluteCoordinate:pt];
    CGContextMoveToPoint(context, pt.x, pt.y);
    for (int i = 1; i < pointCount; i++)
    {
        pt = [aFreedraw pointAtIndex:i];
        pt = [self absoluteCoordinate:pt];
        CGContextAddLineToPoint(context, pt.x, pt.y);
    }
    CGContextStrokePath(context);
}

- (void)drawBlast:(CGContextRef)context withBlast:(CustomShape *)aBlast
{
    // draw function
    
    CGContextSetStrokeColorWithColor(context, aBlast.shapeColor.CGColor);

    float radiusY = fabs(aBlast.centerPt.y - aBlast.radius);
    float radiusX = fabs(aBlast.centerPt.x - aBlast.radius);
    
    radiusY = [self changeAbsolute:aBlast.radius];
    radiusX = [self changeAbsolute:aBlast.radius];
    
    CGFloat centerPtX = [self changeAbsolute:aBlast.centerPt.x];
    CGFloat centerPtY = [self changeAbsolute:aBlast.centerPt.y];
    
    UIColor *xaxisColor = [UIColor colorWithHexString:@"#942c92"];
    CGContextSetStrokeColorWithColor(context, xaxisColor.CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX, centerPtY);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 4 / 5, centerPtY);
    CGContextStrokePath(context);
    
    UIColor *yaxisColor = [UIColor colorWithHexString:@"#fe8dfd"];
    CGContextSetStrokeColorWithColor(context, yaxisColor.CGColor);
    CGContextMoveToPoint(context, centerPtX, centerPtY - radiusY * 6 / 5);
    CGContextAddLineToPoint(context, centerPtX, centerPtY + radiusY * 6 / 5);
    CGContextStrokePath(context);
    
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 2.5f);
    // black box width , height calculate
    float  bwidth = radiusX * 2.2 / 5 ; float bheight = radiusX * 5.1 / 5;
    CGContextMoveToPoint(context, centerPtX - bwidth, centerPtY + bheight);
    CGContextAddLineToPoint(context, centerPtX - bwidth, centerPtY - bheight);
    CGContextStrokePath(context);
    CGContextMoveToPoint(context, centerPtX + bwidth, centerPtY + bheight);
    CGContextAddLineToPoint(context, centerPtX + bwidth, centerPtY - bheight);
    CGContextStrokePath(context);
    CGContextMoveToPoint(context, centerPtX - bwidth, centerPtY + bheight);
    CGContextAddLineToPoint(context, centerPtX + bwidth, centerPtY + bheight);
    CGContextStrokePath(context);
    CGContextMoveToPoint(context, centerPtX - bwidth, centerPtY - bheight);
    CGContextAddLineToPoint(context, centerPtX + bwidth, centerPtY - bheight);
    CGContextStrokePath(context);
    
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    CGContextSetLineWidth(context, 3.0f);
    // black box width , height calculate
    float  rwidth = radiusX * 1.8 / 5 ; float rheight = radiusX * 5.05 / 5;
    CGContextMoveToPoint(context, centerPtX - rwidth, centerPtY + rheight);
    CGContextAddLineToPoint(context, centerPtX - rwidth, centerPtY - rheight);
    CGContextStrokePath(context);
    CGContextMoveToPoint(context, centerPtX + rwidth, centerPtY + rheight);
    CGContextAddLineToPoint(context, centerPtX + rwidth, centerPtY - rheight);
    CGContextStrokePath(context);
    CGContextMoveToPoint(context, centerPtX - rwidth, centerPtY + rheight);
    CGContextAddLineToPoint(context, centerPtX + rwidth, centerPtY + rheight);
    CGContextStrokePath(context);
    CGContextMoveToPoint(context, centerPtX - rwidth, centerPtY - rheight);
    CGContextAddLineToPoint(context, centerPtX + rwidth, centerPtY - rheight);
    CGContextStrokePath(context);
    
    //
    CGContextSetLineWidth(context, 2.0f);
    float  rwidth1 = radiusX * 1.8 / 5 ; float rheight1 = radiusX * 1.3 / 5;
    CGContextMoveToPoint(context, centerPtX - rwidth1, centerPtY + rheight1);
    CGContextAddLineToPoint(context, centerPtX + rwidth1, centerPtY + rheight1);
    CGContextStrokePath(context);
    CGContextMoveToPoint(context, centerPtX - rwidth1, centerPtY - rheight1);
    CGContextAddLineToPoint(context, centerPtX + rwidth1, centerPtY - rheight1);
    CGContextStrokePath(context);
    
    // green color polygon
    CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
    CGContextSetLineWidth(context, 2.4f);
    
    CGContextMoveToPoint(context, centerPtX + radiusX * 0.5 / 5, centerPtY - radiusY * 5 / 5);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 1.8 / 5, centerPtY - radiusY * 5 / 5);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 1.8 / 5, centerPtY + radiusY * 5.05 / 5);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 2.8 / 5, centerPtY + radiusY * 5.05 / 5);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 2.8 / 5, centerPtY - radiusY * 0.7 / 5);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 0.5 / 5, centerPtY - radiusY * 5 / 5);
    CGContextStrokePath(context);

    //
    CGContextSetLineWidth(context, 1.5f);
    CGContextMoveToPoint(context, centerPtX - radiusX * 2.8 / 5, centerPtY + radiusY * 4.2 / 5);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 2.8 / 5, centerPtY + radiusY * 4.2 / 5);
    CGContextStrokePath(context);

    CGContextMoveToPoint(context, centerPtX - radiusX * 1.8 / 5, centerPtY + radiusY * 5.4 / 5);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 1.8 / 5, centerPtY + radiusY * 5.4 / 5);
    CGContextStrokePath(context);

}

- (void)drawCustomShapeCtrl:(CGContextRef)context withCustomShape:(CustomShape *)aShape
{
    if (aShape.isCandi)
    {
        CGContextSetStrokeColorWithColor(context, aShape.shapeColor.CGColor);

        CGFloat centerPtX = [self changeAbsolute:aShape.centerPt.x];
        CGFloat centerPtY = [self changeAbsolute:aShape.centerPt.y];
        CGFloat radius = [self changeAbsolute:aShape.radius];
        
        CGContextAddArc(context, centerPtX, centerPtY, kCtrlPtRadius, 0.0f, M_PI * 2.0f, 0);
        CGContextDrawPath(context, kCGPathFillStroke);
        
        CGContextAddArc(context, centerPtX, centerPtY + radius, kCtrlPtRadius, 0.0f, M_PI * 2.0f, 0);
        CGContextDrawPath(context, kCGPathFillStroke);
    }
}

- (void)drawAutoline:(CGContextRef)context withAutoLine:(CustomShape *)aAutoline
{
    // draw function
    
    CGContextSetStrokeColorWithColor(context, aAutoline.shapeColor.CGColor);
    
    float radiusY = fabs(aAutoline.centerPt.y - aAutoline.radius);
    float radiusX = fabs(aAutoline.centerPt.x - aAutoline.radius);
    
    radiusY = [self changeAbsolute:aAutoline.radius];
    radiusX = [self changeAbsolute:aAutoline.radius];
    
    CGFloat centerPtX = [self changeAbsolute:aAutoline.centerPt.x];
    CGFloat centerPtY = [self changeAbsolute:aAutoline.centerPt.y];
    
    UIColor *greenColor = [UIColor colorWithHexString:@"#00fa00"];
    CGContextSetStrokeColorWithColor(context, greenColor.CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX * 1.3 / 7.0f, centerPtY - radiusY * 5.9 / 7.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 1.3 / 7.0f, centerPtY + radiusY * 5.9 / 7.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 1.3 / 7.0f, centerPtY + radiusY * 5.9 / 7.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 1.3 / 7.0f, centerPtY - radiusY * 5.9 / 7.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 1.3 / 7.0f, centerPtY - radiusY * 5.9 / 7.0f);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, centerPtX - radiusX * 3.8 / 7.0f, centerPtY + radiusY * 5.9 / 7.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 3.8 / 7.0f, centerPtY + radiusY * 5.9 / 7.0f);
    CGContextStrokePath(context);

    UIColor *pinkColor = [UIColor colorWithHexString:@"#d069bd"];
    CGContextSetStrokeColorWithColor(context, pinkColor.CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX * 0.4 / 7.0f, centerPtY + radiusY * 6.6 / 7.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 0.4 / 7.0f, centerPtY - radiusY * 6.6 / 7.0f);
    CGContextStrokePath(context);
    
    UIColor *redColor = [UIColor colorWithHexString:@"#d94c2f"];
    CGContextSetStrokeColorWithColor(context, redColor.CGColor);
    CGContextMoveToPoint(context, centerPtX + radiusX * 0.4 / 7.0f, centerPtY + radiusY * 6.6 / 7.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 0.4 / 7.0f, centerPtY - radiusY * 6.6 / 7.0f);
    CGContextStrokePath(context);
    
    UIColor *yellowColor = [UIColor colorWithHexString:@"#e6e41d"];
    CGContextSetStrokeColorWithColor(context, yellowColor.CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX * 4.8 / 7.0f, centerPtY - radiusY * 5.6 / 7.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 4.2 / 7.0f, centerPtY + radiusY * 4.2 / 7.0f);
    CGContextStrokePath(context);
    
    UIColor *whiteColor = [UIColor whiteColor];
    CGContextSetStrokeColorWithColor(context, whiteColor.CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX * 3 / 7.0f, centerPtY - radiusY);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 4.2 / 7.0f, centerPtY + radiusY * 4.2 / 7.0f);
    CGContextStrokePath(context);
}

- (void)drawBalanceBox:(CGContextRef)context withBalanceBox:(CustomShape *)aBalancebox
{
    float radiusY = fabs(aBalancebox.centerPt.y - aBalancebox.radius);
    float radiusX = fabs(aBalancebox.centerPt.x - aBalancebox.radius);
    radiusY = [self changeAbsolute:aBalancebox.radius];
    radiusX = [self changeAbsolute:aBalancebox.radius];
    
    CGFloat centerPtX = [self changeAbsolute:aBalancebox.centerPt.x];
    CGFloat centerPtY = [self changeAbsolute:aBalancebox.centerPt.y];
    
    UIColor *blackColor = [UIColor blackColor];
    CGContextSetStrokeColorWithColor(context, blackColor.CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX * 210 / 500.0f, centerPtY - radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 210 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 210 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 210 / 500.0f, centerPtY - radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 210 / 500.0f, centerPtY - radiusY * 500 / 500.0f);
    CGContextStrokePath(context);
    
    UIColor *redColor = [UIColor colorWithHexString:@"#f22c0a"];
    CGContextSetStrokeColorWithColor(context, redColor.CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX * 165 / 500.0f, centerPtY - radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 165 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextMoveToPoint(context, centerPtX + radiusX * 165 / 500.0f, centerPtY - radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 165 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextMoveToPoint(context, centerPtX - radiusX * 165 / 500.0f, centerPtY - radiusY * 140 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 165 / 500.0f, centerPtY - radiusY * 140 / 500.0f);
    CGContextMoveToPoint(context, centerPtX - radiusX * 165 / 500.0f, centerPtY + radiusY * 140 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 165 / 500.0f, centerPtY + radiusY * 140 / 500.0f);
    CGContextStrokePath(context);

    UIColor *pinkColor = [UIColor colorWithHexString:@"#fe47ca"];
    CGContextSetStrokeColorWithColor(context, pinkColor.CGColor);
    CGContextMoveToPoint(context, centerPtX , centerPtY - radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX , centerPtY + radiusY * 500 / 500.0f);
    CGContextStrokePath(context);

    UIColor *greenColor = [UIColor colorWithHexString:@"#00f900"];
    CGContextSetStrokeColorWithColor(context, greenColor.CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX * 210 / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * (210 - 100) / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * (210 - 100) / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 210 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 210 / 500.0f, centerPtY + radiusY * 400 / 500.0f);

    CGContextMoveToPoint(context, centerPtX + radiusX * 210 / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * (210 - 100) / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * (210 - 100) / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 210 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 210 / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    
    CGContextStrokePath(context);

    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX * 270 / 500.0f, centerPtY + radiusY * 440 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 270 / 500.0f, centerPtY + radiusY * 440 / 500.0f);

    CGContextMoveToPoint(context, centerPtX - radiusX * 270 / 500.0f, centerPtY + radiusY * (440 + 10) / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 270 / 500.0f, centerPtY + radiusY * (440 - 10) / 500.0f);
    
    CGContextMoveToPoint(context, centerPtX + radiusX * 270 / 500.0f, centerPtY + radiusY * (440 + 10) / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 270 / 500.0f, centerPtY + radiusY * (440 - 10) / 500.0f);
    
    CGContextStrokePath(context);

}

- (void)drawCenterAlignmentLine:(CGContextRef)context withCenterAlignmentLine:(CustomShape *)aCenterAlignmentLine
{
    float radiusY = fabs(aCenterAlignmentLine.centerPt.y - aCenterAlignmentLine.radius);
    float radiusX = fabs(aCenterAlignmentLine.centerPt.x - aCenterAlignmentLine.radius);
    radiusY = [self changeAbsolute:aCenterAlignmentLine.radius];
    radiusX = [self changeAbsolute:aCenterAlignmentLine.radius];
    
    CGFloat centerPtX = [self changeAbsolute:aCenterAlignmentLine.centerPt.x];
    CGFloat centerPtY = [self changeAbsolute:aCenterAlignmentLine.centerPt.y];
    
    UIColor *pinkColor = [UIColor colorWithHexString:@"#fe47ca"];
    CGContextSetStrokeColorWithColor(context, pinkColor.CGColor);
    CGContextMoveToPoint(context, centerPtX , centerPtY - radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX , centerPtY + radiusY * 500 / 500.0f);
    CGContextStrokePath(context);
    
    UIColor *greenColor = [UIColor colorWithHexString:@"#00f900"];
    CGContextSetStrokeColorWithColor(context, greenColor.CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX * 210 / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * (210 - 100) / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * (210 - 100) / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 210 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 210 / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    
    CGContextMoveToPoint(context, centerPtX + radiusX * 210 / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * (210 - 100) / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * (210 - 100) / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 210 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 210 / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    
    CGContextStrokePath(context);

    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX * 270 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 270 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    
    CGContextMoveToPoint(context, centerPtX - radiusX * 270 / 500.0f, centerPtY + radiusY * (500 + 10) / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 270 / 500.0f, centerPtY + radiusY * (500 - 10) / 500.0f);
    
    CGContextMoveToPoint(context, centerPtX + radiusX * 270 / 500.0f, centerPtY + radiusY * (500 + 10) / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 270 / 500.0f, centerPtY + radiusY * (500 - 10) / 500.0f);
    
    CGContextStrokePath(context);
}

- (void)drawCenterBalanceLine:(CGContextRef)context withCenterBalanceLine:(CustomShape *)aCenterBalanceLine
{
    float radiusY = fabs(aCenterBalanceLine.centerPt.y - aCenterBalanceLine.radius);
    float radiusX = fabs(aCenterBalanceLine.centerPt.x - aCenterBalanceLine.radius);
    radiusY = [self changeAbsolute:aCenterBalanceLine.radius];
    radiusX = [self changeAbsolute:aCenterBalanceLine.radius];
    
    CGFloat centerPtX = [self changeAbsolute:aCenterBalanceLine.centerPt.x];
    CGFloat centerPtY = [self changeAbsolute:aCenterBalanceLine.centerPt.y];
    
    UIColor *pinkColor = [UIColor colorWithHexString:@"#7b1e61"];
    CGContextSetStrokeColorWithColor(context, pinkColor.CGColor);
    CGContextMoveToPoint(context, centerPtX , centerPtY - radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX , centerPtY + radiusY * 500 / 500.0f);
    CGContextStrokePath(context);
    
    UIColor *greenColor = [UIColor colorWithHexString:@"#00f900"];
    CGContextSetStrokeColorWithColor(context, greenColor.CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX * 50 / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * (50 - 100) / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * (50 - 100) / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 50 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 50 / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    
    CGContextMoveToPoint(context, centerPtX - radiusX * 150 / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * (150 - 100) / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * (150 - 100) / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 150 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 150 / 500.0f, centerPtY + radiusY * 400 / 500.0f);
    
    CGContextStrokePath(context);

    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX * 270 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 270 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    
    CGContextMoveToPoint(context, centerPtX - radiusX * 270 / 500.0f, centerPtY + radiusY * (500 + 10) / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 270 / 500.0f, centerPtY + radiusY * (500 - 10) / 500.0f);
    
    CGContextMoveToPoint(context, centerPtX + radiusX * 270 / 500.0f, centerPtY + radiusY * (500 + 10) / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 270 / 500.0f, centerPtY + radiusY * (500 - 10) / 500.0f);
    
    CGContextStrokePath(context);
}

- (void)drawCenterCrosshair:(CGContextRef)context withCrossHair:(CustomShape *)aCrossHair
{
    float radiusY = fabs(aCrossHair.centerPt.y - aCrossHair.radius);
    float radiusX = fabs(aCrossHair.centerPt.x - aCrossHair.radius);
    radiusY = [self changeAbsolute:aCrossHair.radius];
    radiusX = [self changeAbsolute:aCrossHair.radius];
    
    CGFloat centerPtX = [self changeAbsolute:aCrossHair.centerPt.x];
    CGFloat centerPtY = [self changeAbsolute:aCrossHair.centerPt.y];
    
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX, centerPtY);
    CGContextAddLineToPoint(context, centerPtX + radiusX, centerPtY);
    
    CGContextMoveToPoint(context, centerPtX , centerPtY - radiusY);
    CGContextAddLineToPoint(context, centerPtX , centerPtY + radiusY);
    CGContextStrokePath(context);

    CGContextAddArc(context, centerPtX, centerPtY, radiusX /  2, 0.0f, M_PI * 2.0f, 0);
    CGContextDrawPath(context, kCGPathStroke);
    CGContextStrokePath(context);

}

- (void)drawSkelton:(CGContextRef)context withSkelton:(CustomShape *)aSkelton
{

    float radiusY = fabs(aSkelton.centerPt.y - aSkelton.radius);
    float radiusX = fabs(aSkelton.centerPt.x - aSkelton.radius);
    radiusY = [self changeAbsolute:aSkelton.radius];
    radiusX = [self changeAbsolute:aSkelton.radius];
    CGFloat centerPtX = [self changeAbsolute:aSkelton.centerPt.x];
    CGFloat centerPtY = [self changeAbsolute:aSkelton.centerPt.y];

    UIColor *yellowColor = [UIColor colorWithHexString:@"#f6cd36"];
    CGContextSetStrokeColorWithColor(context, yellowColor.CGColor);
    CGContextMoveToPoint(context, centerPtX + radiusX * 110 / 500.0f, centerPtY - radiusY * 440 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 190 / 500.0f, centerPtY - radiusY * 80 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX , centerPtY + radiusY * 160 / 500.0f);

    CGContextMoveToPoint(context, centerPtX , centerPtY - radiusY * 300 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX , centerPtY + radiusY * 500 / 500.0f);
    
    CGContextStrokePath(context);

    [self drawLens:context center:CGPointMake(centerPtX + radiusX * 110 / 500.0f, centerPtY - radiusY * 440 / 500.0f) radius:radiusX];
    [self drawLens:context center:CGPointMake(centerPtX - radiusX * 190 / 500.0f, centerPtY - radiusY * 80 / 500.0f) radius:radiusX];
    [self drawLens:context center:CGPointMake(centerPtX , centerPtY + radiusY * 160 / 500.0f) radius:radiusX];
    [self drawLens:context center:CGPointMake(centerPtX , centerPtY - radiusY * 300 / 500.0f) radius:radiusX];
    [self drawLens:context center:CGPointMake(centerPtX , centerPtY + radiusY * 460 / 500.0f) radius:radiusX];
    [self drawLens:context center:CGPointMake(centerPtX , centerPtY - radiusY * 10 / 500.0f) radius:radiusX];
    [self drawLens:context center:CGPointMake(centerPtX , centerPtY - radiusY * 140 / 500.0f) radius:radiusX];

    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX * 270 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 270 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    
    CGContextMoveToPoint(context, centerPtX - radiusX * 270 / 500.0f, centerPtY + radiusY * (500 + 10) / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 270 / 500.0f, centerPtY + radiusY * (500 - 10) / 500.0f);
    
    CGContextMoveToPoint(context, centerPtX + radiusX * 270 / 500.0f, centerPtY + radiusY * (500 + 10) / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 270 / 500.0f, centerPtY + radiusY * (500 - 10) / 500.0f);
    
    CGContextStrokePath(context);
}

- (void)drawLens:(CGContextRef)context center:(CGPoint)centerPt radius:(CGFloat)radius
{
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    
    CGContextAddArc(context, centerPt.x, centerPt.y,  radius * 40.0f / 500.0f , 0.0f, M_PI * 2.0f, 0);
    CGContextAddArc(context, centerPt.x, centerPt.y,  radius * 25.0f / 500.0f, 0.0f, M_PI * 2.0f, 0);
    CGContextDrawPath(context, kCGPathStroke);
    
    CGContextMoveToPoint(context, centerPt.x , centerPt.y - radius * 50.0f / 500.0f);
    CGContextAddLineToPoint(context, centerPt.x , centerPt.y + radius * 50.0f / 500.0f);
    
    CGContextMoveToPoint(context, centerPt.x - radius * 50.0f / 500.0f , centerPt.y);
    CGContextAddLineToPoint(context, centerPt.x + radius * 50.0f / 500.0f , centerPt.y);
    CGContextStrokePath(context);

    CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"#f6cd36"].CGColor);
    CGContextAddArc(context, centerPt.x, centerPt.y,  radius * 10.0f / 500.0f, 0.0f, M_PI * 2.0f, 0);
    CGContextDrawPath(context, kCGPathFillStroke);

    CGContextMoveToPoint(context, centerPt.x , centerPt.y - radius * 6.0f / 500.0f);
    CGContextAddLineToPoint(context, centerPt.x , centerPt.y + radius * 6.0f / 500.0f);
    
    CGContextMoveToPoint(context, centerPt.x - radius * 6.0f / 500.0f , centerPt.y);
    CGContextAddLineToPoint(context, centerPt.x + radius * 6.0f / 500.0f , centerPt.y);
    
    CGContextStrokePath(context);
}

- (void)drawSpineAngle:(CGContextRef)context withSpineAngle:(CustomShape *)aSpingAngle
{
    float radiusY = fabs(aSpingAngle.centerPt.y - aSpingAngle.radius);
    float radiusX = fabs(aSpingAngle.centerPt.x - aSpingAngle.radius);
    radiusY = [self changeAbsolute:aSpingAngle.radius];
    radiusX = [self changeAbsolute:aSpingAngle.radius];
    
    CGFloat centerPtX = [self changeAbsolute:aSpingAngle.centerPt.x];
    CGFloat centerPtY = [self changeAbsolute:aSpingAngle.centerPt.y];
    
    UIColor *greenColor = [UIColor colorWithHexString:@"#7b1e61"];
    CGContextSetStrokeColorWithColor(context, greenColor.CGColor);
    CGContextMoveToPoint(context, centerPtX , centerPtY - radiusY * 410 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX , centerPtY + radiusY * 500 / 500.0f);
    CGContextStrokePath(context);

    UIColor *blueColor = [UIColor colorWithHexString:@"#395cc8"];
    CGContextSetStrokeColorWithColor(context, blueColor.CGColor);
    CGContextMoveToPoint(context, centerPtX + radiusX * 140 / 500.0f, centerPtY - radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 230 / 500.0f, centerPtY - radiusY * 40 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 230 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextStrokePath(context);
    
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextMoveToPoint(context, centerPtX - radiusX * 230 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 230 / 500.0f, centerPtY + radiusY * 500 / 500.0f);
    
    CGContextMoveToPoint(context, centerPtX - radiusX * 230 / 500.0f, centerPtY + radiusY * (500 + 10) / 500.0f);
    CGContextAddLineToPoint(context, centerPtX - radiusX * 230 / 500.0f, centerPtY + radiusY * (500 - 10) / 500.0f);
    
    CGContextMoveToPoint(context, centerPtX + radiusX * 230 / 500.0f, centerPtY + radiusY * (500 + 10) / 500.0f);
    CGContextAddLineToPoint(context, centerPtX + radiusX * 230 / 500.0f, centerPtY + radiusY * (500 - 10) / 500.0f);
    
    CGContextStrokePath(context);
    
}

- (void)drawShape:(CGContextRef)context withShape:(Shape *)aShape
{
    if (!aShape)
        return;
    
    switch (aShape.shapeType) {
        case DRAWING_TOOL_CIRCLE:
            [self drawCircle:context withCircle:(Circle *)aShape];
            break;
        case DRAWING_TOOL_LINE:
            [self drawLine:context withLine:(Line *)aShape];
            break;
        case DRAWING_TOOL_DASH:
            [self drawDash:context withLine:(Dash *)aShape];
            break;
        case DRAWING_TOOL_ANGLE:
            [self drawAngle:context withAngle:(Angle *)aShape];
            break;
        case DRAWING_TOOL_FREEDRAW:
            [self drawFreeDraw:context withFreeDraw:(FreeDraw *)aShape];
            break;
        case DRAWING_TOOL_RECTANGLE:
            [self drawRectangle:context withRectangle:(Rectangle *)aShape];
            break;
        case DRAWING_TOOL_BLAST:
            [self drawBlast:context withBlast:(CustomShape *)aShape];
            break;
        case DRAWING_TOOL_AUTOLINE:
            [self drawAutoline:context withAutoLine:(CustomShape *)aShape];
            break;
        case DRAWING_TOOL_BLANCEBOX:
            [self drawBalanceBox:context withBalanceBox:(CustomShape *)aShape];
            break;
        case DRAWING_TOOL_CENTERBALANCELINE:
            [self drawCenterBalanceLine:context withCenterBalanceLine:(CustomShape *)aShape];
            break;
        case DRAWING_TOOL_CENTERALIGNMENTLINE:
            [self drawCenterAlignmentLine:context withCenterAlignmentLine:(CustomShape *)aShape];
            break;
        case DRAWING_TOOL_CROSSHAIR:
            [self drawCenterCrosshair:context withCrossHair:(CustomShape *)aShape];
            break;
        case DRAWING_TOOL_SKELTON:
            [self drawSkelton:context withSkelton:(CustomShape *)aShape];
            break;
        case DRAWING_TOOL_SPINEANGLE:
            [self drawSpineAngle:context withSpineAngle:(CustomShape *)aShape];
            break;
        default:
            break;
    }
}

- (void)drawShapeCtrl:(CGContextRef)context withShape:(Shape *)aShape
{
    if (!aShape)
        return;
    
    switch (aShape.shapeType) {
        case DRAWING_TOOL_CIRCLE:
            [self drawCircleCtrl:context withCircle:(Circle *)aShape];
            break;
        case DRAWING_TOOL_LINE:
            [self drawLineCtrl:context withLine:(Line *)aShape];
            break;
        case DRAWING_TOOL_DASH:
            [self drawDashCtrl:context withLine:(Dash *)aShape];
            break;
        case DRAWING_TOOL_ANGLE:
            [self drawAngleCtrl:context withAngle:(Angle *)aShape];
            break;
        case DRAWING_TOOL_FREEDRAW:
            [self drawFreeDrawCtrl:context withFreeDraw:(FreeDraw *)aShape];
            break;
        case DRAWING_TOOL_RECTANGLE:
            [self drawRectangleCtrl:context withRectangle:(Rectangle *)aShape];
            break;
        case DRAWING_TOOL_BLAST:
        case DRAWING_TOOL_AUTOLINE:
        case DRAWING_TOOL_BLANCEBOX:
        case DRAWING_TOOL_CENTERALIGNMENTLINE:
        case DRAWING_TOOL_CENTERBALANCELINE:
        case DRAWING_TOOL_CROSSHAIR:
        case DRAWING_TOOL_SKELTON:
        case DRAWING_TOOL_SPINEANGLE:
        default:
            [self drawCustomShapeCtrl:context withCustomShape:(CustomShape *)aShape];
            break;
    }
}

- (void)drawShapesOnBoard:(CGContextRef)context
{
    CGContextSaveGState(context);
    
    CGContextSetFillColorWithColor(context, [UIColor darkGrayColor].CGColor);
    CGContextSetLineWidth(context, kLineWidth);
    
    int shapeCount = (int)[mShapeList count];
    for (int i = 0; i < shapeCount; i++)
    {
        Shape *aShape = (Shape *)[mShapeList objectAtIndex:i];
        [self drawShape:context withShape:aShape];
    }
    
    [self drawShape:context withShape:mTempShape];
    [self drawShape:context withShape:mCandShape];
    
    CGContextRestoreGState(context);
}

- (void)drawShapeCtrlsOnBoard:(CGContextRef)context
{
    CGContextSaveGState(context);
    
    CGContextSetFillColorWithColor(context, [UIColor darkGrayColor].CGColor);
    CGContextSetLineWidth(context, kLineWidth);
    
    int shapeCount = (int)[mShapeList count];
    for (int i = 0; i < shapeCount; i++)
    {
        Shape *aShape = (Shape *)[mShapeList objectAtIndex:i];
        [self drawShapeCtrl:context withShape:aShape];
    }
    
    [self drawShapeCtrl:context withShape:mTempShape];
    [self drawShapeCtrl:context withShape:mCandShape];
    
    CGContextRestoreGState(context);
}

- (void)selectNewCandiShape:(CGPoint)tapPt
{
    //Check Which is Selected
    tapPt = [self relativeCoordinate:tapPt];
    if (mEditMode == EDIT_MODE_NONE)
    {
        Shape *mNearestShape = nil;
        float minDistance = FLT_MAX - 1;
        
        int shapeCount = (int)[mShapeList count];
        for (int i = 0; i < shapeCount; i++)
        {
            Shape *aShape = (Shape *)[mShapeList objectAtIndex:i];
            CGFloat distance = [aShape distanceFromPt:tapPt];
            
            if (distance < minDistance)
            {
                minDistance = distance;
                mNearestShape = aShape;
            }
        }
        
        if (mNearestShape)
        {
            mNearestShape.isCandi = YES;
            mCandShape = mNearestShape;
            
            [mShapeList removeObject:mNearestShape];
            
            mShapeType = mCandShape.shapeType;
            
            
            NSLog(@"%@", NSStringFromClass([mCandShape class]));
            
            if ([self.delegate respondsToSelector:@selector(drawBoardViewPropertyChanged:withInfo:)])
            {
                NSMutableDictionary *infoDic = [NSMutableDictionary dictionary];
                [infoDic setObject:[NSNumber numberWithInt:mCandShape.shapeColorType] forKey:kDrawingColorKey];
                [infoDic setObject:[NSNumber numberWithInt:mCandShape.shapeType] forKey:kDrawingShapeKey];
                
                [self.delegate drawBoardViewPropertyChanged:self withInfo:infoDic];
            }
        }
    }
}

- (void)selectDeletableCandiShape:(CGPoint)tapPt
{
    //Check Which is Selected
    if (mIsDeletable)
    {
        Shape *mNearestShape = nil;
        
        int shapeCount = (int)[mShapeList count];
        for (int i = 0; i < shapeCount; i++)
        {
            Shape *aShape = (Shape *)[mShapeList objectAtIndex:i];
            if ([aShape IsTappedDeleteCtrlPt:tapPt])
            {
                mNearestShape = aShape;
            }
        }
        
        if (mNearestShape)
        {
            mNearestShape.isCandi = YES;
            mTempShape = mNearestShape;
        }
    }
}

#pragma mark - Touch Event
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startDrawing" object:nil];
    
	UITouch *touch = [[touches allObjects] objectAtIndex:0];
    if ([touch tapCount] > 1)
    {
        return;
    }
    
	mFirstPt = [touch locationInView:self];
	mLastPt = [touch locationInView:self];

    if (mIsDeletable)
    {
        [self selectDeletableCandiShape:mFirstPt];
        return;
    }
    
    mEditMode = EDIT_MODE_NONE;
    mTempIsCandi = NO;
    
    if (mCandShape)
    {
        switch (mCandShape.shapeType) {
            case DRAWING_TOOL_CIRCLE:
            {
                Circle *aCircle = (Circle *)mCandShape;
                
                CGPoint centerPt = [self absoluteCoordinate:aCircle.centerPt];
                CGPoint bottomPt = [self absoluteCoordinate:CGPointMake(aCircle.centerPt.x, aCircle.centerPt.y + aCircle.radius)];
                
                if (isEqualPoint(bottomPt, mFirstPt, kCtrlPtRadius + kLineWidth))
                {
                    mEditMode = EDIT_MODE_END_PT;
                } else if (isEqualPoint(centerPt, mFirstPt, kCtrlPtRadius + kLineWidth)) {
                    mEditMode = EDIT_MODE_CENTER_PT;
                }
            }
                break;
                
            case DRAWING_TOOL_LINE:
            {
                Line *aLine = (Line *)mCandShape;
                CGPoint endPt = [self absoluteCoordinate:aLine.endPt];
                CGPoint startPt = [self absoluteCoordinate:aLine.startPt];

                if (isEqualPoint(endPt, mFirstPt, kCtrlPtRadius + kLineWidth))
                {
                    mEditMode = EDIT_MODE_END_PT;
                } else if (isEqualPoint(startPt, mFirstPt, kCtrlPtRadius + kLineWidth)) {
                    mEditMode = EDIT_MODE_START_PT;
                }
            }
                break;
            case DRAWING_TOOL_DASH:
            {
                Dash *aLine = (Dash *)mCandShape;
                
                if (isEqualPoint(aLine.endPt, mFirstPt, kCtrlPtRadius + kLineWidth))
                {
                    mEditMode = EDIT_MODE_END_PT;
                } else if (isEqualPoint(aLine.startPt, mFirstPt, kCtrlPtRadius + kLineWidth)) {
                    mEditMode = EDIT_MODE_START_PT;
                }
            }
                break;
                
            case DRAWING_TOOL_ANGLE:
            {
                Angle *aAngle = (Angle *)mCandShape;
                
                CGPoint endPt = [self absoluteCoordinate:aAngle.endPt];
                CGPoint startPt = [self absoluteCoordinate:aAngle.startPt];
                CGPoint centerPt = [self absoluteCoordinate:aAngle.centerPt];

                if (isEqualPoint(centerPt, mFirstPt, kCtrlPtRadius + kLineWidth))
                {
                    mEditMode = EDIT_MODE_CENTER_PT;
                } else if (isEqualPoint(endPt, mFirstPt, kCtrlPtRadius + kLineWidth)) {
                    mEditMode = EDIT_MODE_END_PT;
                } else if (isEqualPoint(startPt, mFirstPt, kCtrlPtRadius + kLineWidth)) {
                    mEditMode = EDIT_MODE_START_PT;
                }
            }
                break;
                
            case DRAWING_TOOL_RECTANGLE:
            {
                Rectangle *aRectangle = (Rectangle *)mCandShape;
                CGPoint endPt = [self absoluteCoordinate:aRectangle.endPt];
                CGPoint startPt = [self absoluteCoordinate:aRectangle.startPt];
                CGPoint centerPt = [self absoluteCoordinate:aRectangle.centerPt];

                if (isEqualPoint(centerPt, mFirstPt, kCtrlPtRadius + kLineWidth))
                {
                    mEditMode = EDIT_MODE_CENTER_PT;
                }
                else if (isEqualPoint(endPt, mFirstPt, kCtrlPtRadius + kLineWidth))
                {
                    mEditMode = EDIT_MODE_END_PT;
                }
                else if (isEqualPoint(startPt, mFirstPt, kCtrlPtRadius + kLineWidth))
                {
                    mEditMode = EDIT_MODE_START_PT;
                }
            }
                break;
            default:
            {
                CustomShape *aShape = (CustomShape *)mCandShape;
                CGPoint centerPt = [self absoluteCoordinate:aShape.centerPt];
                CGPoint bottomPt = [self absoluteCoordinate:CGPointMake(aShape.centerPt.x, aShape.centerPt.y + aShape.radius)];
                
                if (isEqualPoint(bottomPt, mFirstPt, kCtrlPtRadius + kLineWidth))
                {
                    mEditMode = EDIT_MODE_END_PT;
                } else if (isEqualPoint(centerPt, mFirstPt, kCtrlPtRadius + kLineWidth)) {
                    mEditMode = EDIT_MODE_CENTER_PT;
                }
            }
                break;
        }
    }
    
    if (mEditMode == EDIT_MODE_NONE)
    {
        switch (mShapeType) {
            case DRAWING_TOOL_CIRCLE:
            {
                mTempShape = [[Circle alloc] init];
                CGPoint centerPt = [self relativeCoordinate:mFirstPt];
                [(Circle *)mTempShape setCenterPt:centerPt];
            }
                break;
            case DRAWING_TOOL_LINE:
            {
                mTempShape = [[Line alloc] init];
                CGPoint firstPt = [self relativeCoordinate:mFirstPt];

                [(Line *)mTempShape setStartPt:firstPt];
                [(Line *)mTempShape setEndPt:firstPt];
            }
                break;
            case DRAWING_TOOL_DASH:
            {
                mTempShape = [[Dash alloc] init];
                [(Dash *)mTempShape setStartPt:mFirstPt];
                [(Dash *)mTempShape setEndPt:mFirstPt];
            }
                break;
            case DRAWING_TOOL_ANGLE:
            {
                mTempShape = [[Angle alloc] init];
                CGPoint startPt = [self relativeCoordinate:CGPointMake(mFirstPt.x, mFirstPt.y - 1.0f)];
                CGPoint centerPt = [self relativeCoordinate:mFirstPt];
                CGPoint endPt = [self relativeCoordinate:CGPointMake(mFirstPt.x + 50.0f, mFirstPt.y + 50.0f)];

                [(Angle *)mTempShape setStartPt:startPt];
                [(Angle *)mTempShape setCenterPt:centerPt];
                [(Angle *)mTempShape setEndPt:endPt];
                [(Angle *)mTempShape calcValue];
            }
                break;
            case DRAWING_TOOL_FREEDRAW:
            {
                mTempShape = [[FreeDraw alloc] init];
                CGPoint firstPt = [self relativeCoordinate:mFirstPt];

                [(FreeDraw *)mTempShape addPoint:firstPt];
                [(FreeDraw *)mTempShape addPoint:firstPt];
            }
                break;
            case DRAWING_TOOL_RECTANGLE:
            {
                mTempShape = [[Rectangle alloc] init];

                CGPoint startPt = [self relativeCoordinate:CGPointMake(mFirstPt.x, mFirstPt.y + 50)];
                CGPoint centerPt = [self relativeCoordinate:mFirstPt];
                CGPoint endPt = [self relativeCoordinate:CGPointMake(mFirstPt.x + 50, mFirstPt.y)];
                
                [(Rectangle *)mTempShape setCenterPt:centerPt];
                [(Rectangle *)mTempShape setStartPt:startPt];
                [(Rectangle *)mTempShape setEndPt:endPt];
            }
                break;
            default:
            {
                mTempShape = [[CustomShape alloc] init];
                mTempShape.shapeType = mShapeType;
                CGPoint centerPt = [self relativeCoordinate:mFirstPt];
                [(CustomShape *)mTempShape setCenterPt:centerPt];
            }
                break;
        }
        
        mTempShape.shapeColorType = mShapeColorType;
        mTempShape.shapeColor = mShapeColor;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [[touches allObjects] objectAtIndex:0];
	mLastPt = [touch locationInView:self];

    if (mIsDeletable)
    {
        return;
    }
    
    if (mEditMode == EDIT_MODE_NONE)
    {
        if (mCandShape && !isEqualPoint(mFirstPt, mLastPt, kCtrlPtRadius + kLineWidth))
        {
            mTempIsCandi = YES;//(mTempShape.shapeType != DRAWING_TOOL_FREEDRAW) ? YES : NO;
            mCandShape = nil;
        }
        
        if (mTempShape) {
            switch (mTempShape.shapeType) {
                case DRAWING_TOOL_CIRCLE:
                {
                    CGFloat distance = distanceBetween2Points(mFirstPt, mLastPt);
                    [(Circle *)mTempShape setRadius:[self changeRelative:distance]];
                }
                    break;
                case DRAWING_TOOL_LINE:
                {
                    [(Line *)mTempShape setEndPt:[self relativeCoordinate:mLastPt]];
                }
                    break;
                case DRAWING_TOOL_DASH:
                {
                    [(Dash*)mTempShape setEndPt:mLastPt];
                }
                    break;
                case DRAWING_TOOL_ANGLE:
                {
                    [(Angle *)mTempShape setCenterPt:[self relativeCoordinate:mLastPt]];
                    [(Angle *)mTempShape calcValue];
                }
                    break;
                case DRAWING_TOOL_FREEDRAW:
                {
                    [(FreeDraw *)mTempShape addPoint:[self relativeCoordinate:mLastPt]];
                }
                    break;
                case DRAWING_TOOL_RECTANGLE:
                {
                    CGPoint startPt = [self relativeCoordinate:CGPointMake(mLastPt.x, mLastPt.y + 50)];
                    CGPoint centerPt = [self relativeCoordinate:mLastPt];
                    CGPoint endPt = [self relativeCoordinate:CGPointMake(mLastPt.x + 50, mLastPt.y)];
                    
                    [(Rectangle *)mTempShape setCenterPt:centerPt];
                    [(Rectangle *)mTempShape setStartPt:startPt];
                    [(Rectangle *)mTempShape setEndPt:endPt];
                    
                }
                    break;
                default:
                    [(CustomShape *)mTempShape setRadius:[self changeRelative:100]];
                    break;
            }
        }
    } else {
        switch (mCandShape.shapeType) {
            case DRAWING_TOOL_CIRCLE:
            {
                Circle *aCircle = (Circle *)mCandShape;
                if (mEditMode == EDIT_MODE_CENTER_PT)
                {
                    [aCircle setCenterPt:[self relativeCoordinate:mLastPt]];

                } else {
                    CGFloat distance = distanceBetween2Points(aCircle.centerPt, [self relativeCoordinate:mLastPt]);
                    [aCircle setRadius:distance];

                }
            }
                break;
                
            case DRAWING_TOOL_LINE:
            {
                Line *aLine = (Line *)mCandShape;
                if (mEditMode == EDIT_MODE_START_PT)
                {
                    [aLine setStartPt:[self relativeCoordinate:mLastPt]];

                } else if (mEditMode == EDIT_MODE_END_PT) {
                    [aLine setEndPt:[self relativeCoordinate:mLastPt]];

                }
            }
                break;
            case DRAWING_TOOL_DASH:
            {
                Dash *aLine = (Dash *)mCandShape;
                if (mEditMode == EDIT_MODE_START_PT)
                {
                    [aLine setStartPt:mLastPt];
                } else if (mEditMode == EDIT_MODE_END_PT) {
                    [aLine setEndPt:mLastPt];
                }
            }
                break;
            case DRAWING_TOOL_ANGLE:
            {
                Angle *aAngle = (Angle *)mCandShape;
                if (mEditMode == EDIT_MODE_START_PT)
                {
                    [aAngle setStartPt:[self relativeCoordinate:mLastPt]];

                } else if (mEditMode == EDIT_MODE_END_PT) {
                    [aAngle setEndPt:[self relativeCoordinate:mLastPt]];

                } else if (mEditMode == EDIT_MODE_CENTER_PT) {
                    [aAngle setCenterPt:[self relativeCoordinate:mLastPt]];

                }
                [aAngle calcValue];
            }
                break;
            case DRAWING_TOOL_RECTANGLE:
            {
                Rectangle *aRectangle = (Rectangle *)mCandShape;
                if (mEditMode == EDIT_MODE_CENTER_PT)
                {
                    float offsetX ,offsetY;
                    offsetX = [self changeRelative:mLastPt.x] - aRectangle.centerPt.x;
                    offsetY = [self changeRelative:mLastPt.y] - aRectangle.centerPt.y;
                    
                    CGPoint startPt = CGPointMake(aRectangle.startPt.x + offsetX, aRectangle.startPt.y + offsetY);
                    CGPoint centerPt = [self relativeCoordinate:mLastPt];
                    CGPoint endPt = CGPointMake(aRectangle.endPt.x + offsetX, aRectangle.endPt.y + offsetY);
                
                    [aRectangle setCenterPt:centerPt];
                    [aRectangle setStartPt:startPt];
                    [aRectangle setEndPt:endPt];
                    
                }
                else if (mEditMode == EDIT_MODE_START_PT)
                {
                    CGPoint startPt = CGPointMake(aRectangle.startPt.x, [self changeRelative:mLastPt.y]);
                    [aRectangle setStartPt:startPt];

                }
                else if (mEditMode == EDIT_MODE_END_PT)
                {
                    CGPoint endPt = CGPointMake([self changeRelative:mLastPt.x], aRectangle.endPt.y);
                    [aRectangle setEndPt:endPt];

                }
            }
                break;
            
            default:
            {
                CustomShape *aShape = (CustomShape *)mCandShape;
                if (mEditMode == EDIT_MODE_CENTER_PT)
                {
                    [aShape setCenterPt:[self relativeCoordinate:mLastPt]];
                    
                } else {
                    CGFloat distance = distanceBetween2Points(aShape.centerPt, [self relativeCoordinate:mLastPt]);
                    [aShape setRadius:distance];
                    
                }
            }
                break;
        }
    }
    
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"stopDrawing" object:nil];

	UITouch *touch = [[touches allObjects] objectAtIndex:0];
	mLastPt = [touch locationInView:self];

    if (mIsDeletable)
    {
        if (mTempShape && [mTempShape IsTappedDeleteCtrlPt:mLastPt])
        {
            [mShapeList removeObject:mTempShape];
        }

        mTempShape = nil;
        
        [self setNeedsDisplay];
        return;
    }
    
    if (mEditMode == EDIT_MODE_NONE)
    {
        if (mCandShape) {
            mCandShape.isCandi = NO;
            [mShapeList addObject:mCandShape];
            [_delegate finishDraw:self];
            mCandShape = nil;
            
        } else if (mTempShape) {
            if (isEqualPoint(mFirstPt, mLastPt, 1.0f))
            {
                [self selectNewCandiShape:mLastPt];
            } else {
                switch (mTempShape.shapeType) {
                    case DRAWING_TOOL_CIRCLE:
                    {
                        CGFloat distance = distanceBetween2Points(mFirstPt, mLastPt);
                        [(Circle *)mTempShape setRadius:[self changeRelative:distance]];

                    }
                        break;
                        
                    case DRAWING_TOOL_LINE:
                    {
                        [(Line *)mTempShape setEndPt:[self relativeCoordinate:mLastPt]];

                    }
                        break;
                    case DRAWING_TOOL_DASH:
                    {
                        [(Dash *)mTempShape setEndPt:mLastPt];
                    }
                        break;
                        
                    case DRAWING_TOOL_ANGLE:
                    {
                        [(Angle *)mTempShape setCenterPt:[self relativeCoordinate:mLastPt]];
                        [(Angle *)mTempShape calcValue];
                    }
                        break;
                    case DRAWING_TOOL_FREEDRAW:
                    {
                        [(FreeDraw *)mTempShape addPoint:[self relativeCoordinate:mLastPt]];
                    }
                        break;
                    case DRAWING_TOOL_RECTANGLE:
                    {
                        [(Rectangle *)mTempShape setCenterPt:[self relativeCoordinate:mLastPt]];

                    }
                        break;
                    default:
                    {
                        [(CustomShape *)mTempShape setCenterPt:[self relativeCoordinate:mLastPt]];

                    }
                        break;
                }
                
                if (/* DISABLES CODE */ (YES) || mTempIsCandi)
                {
                    mCandShape = mTempShape;
                } else {
                    mTempShape.isCandi = NO;
                    [mShapeList addObject:mTempShape];
                }
            }
        }
        
        mTempShape = nil;
    } else {
//        switch (mCandShape.shapeType) {
//            case DRAWING_TOOL_CIRCLE:
//            {
//                Circle *aCircle = (Circle *)mCandShape;
//                if (mEditMode == EDIT_MODE_CENTER_PT)
//                {
//                    [aCircle setCenterPt:mLastPt];
//                } else {
//                    CGFloat distance = distanceBetween2Points(aCircle.centerPt, mLastPt);
//                    [aCircle setRadius:distance];
//                }
//            }
//                break;
//                
//            default:
//                break;f
//        }
    }
    
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesEnded:touches withEvent:event];
    
    [super touchesCancelled:touches withEvent:event];
}

#pragma mark - Interface
- (void)clearBoard
{
    [mShapeList removeAllObjects];
    mCandShape = nil;
    mTempShape = nil;
    
    mIsDeletable = NO;
   
    [self setNeedsDisplay];
}

- (void)toggleDeletable
{
    mIsDeletable = !mIsDeletable;
    if (mIsDeletable)
    {
        if (mCandShape) {
            mCandShape.isCandi = NO;
            [mShapeList addObject:mCandShape];
            mCandShape = nil;
        }
    } else {
        ;
    }

    [self setNeedsDisplay];
}

- (void)finishDraw
{
    if (mCandShape) {
        mCandShape.isCandi = NO;
        [mShapeList addObject:mCandShape];
        mCandShape = nil;
    }
    
    [self setNeedsDisplay];
}

- (BOOL)isDeletable
{
    return mIsDeletable;
}

- (void)setShapeType:(DRAWING_TOOL)shapeType
{
    mShapeType = shapeType;
    if (mCandShape) {
        mCandShape.isCandi = NO;
        [mShapeList addObject:mCandShape];
        mCandShape = nil;
        
    }
    
    [self setNeedsDisplay];
}

- (void)setShapeColor:(DRAWING_COLOR)shapeColor
{
    switch (shapeColor) {
        case DRAWING_COLOR_RED:
            mShapeColor = [UIColor colorWithHexString:@"#D60000"];
            //mShapeColor = [UIColor redColor];
            break;
        case DRAWING_COLOR_WHITE:
            mShapeColor = [UIColor whiteColor];
            break;
        case DRAWING_COLOR_YELLOW:
            mShapeColor = [UIColor colorWithHexString:@"#F9E401"];
            //mShapeColor = [UIColor yellowColor];
            break;
        case DRAWING_COLOR_BLUE:
            mShapeColor = [UIColor colorWithHexString:@"#38BFFF"];
            //mShapeColor = [UIColor blueColor];
            break;
        case DRAWING_COLOR_GREEN:
            mShapeColor = [UIColor colorWithHexString:@"#4DF410"];
            //mShapeColor = [UIColor greenColor];
            break;
        default:
            break;
    }
    
    mShapeColorType = shapeColor;
}

- (Shape *)getLastShape
{
    return [mShapeList lastObject];
}

- (void)deleteLastShape
{
    [mShapeList removeLastObject];
    [self setNeedsDisplay];
}

- (void)addShape:(Shape *)aShape
{
    [mShapeList addObject:aShape];
    [self setNeedsDisplay];

}

- (CGPoint)relativeCoordinate:(CGPoint)point
{
    return CGPointMake(point.x / self.frame.size.width, point.y / self.frame.size.width);
}

- (CGPoint)absoluteCoordinate:(CGPoint)point
{
    return CGPointMake(point.x * self.frame.size.width, point.y * self.frame.size.width);

}

- (CGFloat)changeAbsolute:(CGFloat)val
{
    return self.frame.size.width * val;
}

- (CGFloat)changeRelative:(CGFloat)val
{
    return  val / self.frame.size.width;
}

@end
