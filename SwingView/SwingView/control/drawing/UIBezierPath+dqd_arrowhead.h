//
//  UIBezierPath+dqd_arrowhead.h
//  GolfSwingAnalysis
//
//  Created by AnCheng on 4/14/16.
//  Copyright © 2016 Zhemin Yin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (dqd_arrowhead)

+ (UIBezierPath *)dqd_bezierPathWithArrowFromPoint:(CGPoint)startPoint
                                           toPoint:(CGPoint)endPoint
                                         tailWidth:(CGFloat)tailWidth
                                         headWidth:(CGFloat)headWidth
                                        headLength:(CGFloat)headLength;
+ (CGAffineTransform)dqd_transformForStartPoint:(CGPoint)startPoint
                                       endPoint:(CGPoint)endPoint
                                         length:(CGFloat)length;
@end
