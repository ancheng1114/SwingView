//
//  Shape.h
//  DrawTest
//
//  Created by xiangmi on 5/25/13.
//  Copyright (c) 2013 xiangmi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define kCtrlPtRadius       8.0f
#define kDistanceLimit      10.0f

typedef enum _tagDRAWING_COLOR {
    DRAWING_COLOR_RED = 0,
    DRAWING_COLOR_WHITE,
    DRAWING_COLOR_YELLOW,
    DRAWING_COLOR_BLUE,
    DRAWING_COLOR_GREEN
} DRAWING_COLOR;

typedef enum _tagDRAWING_TOOL {
    DRAWING_TOOL_NONE = 0,
    DRAWING_TOOL_CIRCLE = 1,
    DRAWING_TOOL_LINE,
    DRAWING_TOOL_ANGLE,
    DRAWING_TOOL_FREEDRAW,
    DRAWING_TOOL_DASH,
    DRAWING_TOOL_ARROW,
    DRAWING_TOOL_RECTANGLE,
    DRAWING_TOOL_BLAST,
    DRAWING_TOOL_AUTOLINE,
    DRAWING_TOOL_BLANCEBOX,
    DRAWING_TOOL_CENTERALIGNMENTLINE,
    DRAWING_TOOL_CENTERBALANCELINE,
    DRAWING_TOOL_CROSSHAIR,
    DRAWING_TOOL_SKELTON,
    DRAWING_TOOL_SPINEANGLE,
    DRAWING_TOOL_TRASH,
    DRAWING_TOOL_CLOSE
} DRAWING_TOOL;

typedef enum _tagEditMode
{
    EDIT_MODE_NONE = 0,
    EDIT_MODE_START_PT,
    EDIT_MODE_END_PT,
    EDIT_MODE_CENTER_PT
} EDIT_MODE;

@interface Shape : NSObject

@property(nonatomic) DRAWING_TOOL shapeType;
@property(nonatomic) BOOL isCandi;
@property(nonatomic) DRAWING_COLOR shapeColorType;
@property(nonatomic, strong) UIColor *shapeColor;

@property (nonatomic) EDIT_MODE shapeEditMode;

- (float)distanceFromPt:(CGPoint)pt;
- (BOOL)IsTappedDeleteCtrlPt:(CGPoint)pt;

@end

