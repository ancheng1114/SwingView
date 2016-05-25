//
//  SwingToolView.m
//  SwingView
//
//  Created by AnCheng on 4/18/16.
//  Copyright © 2016 AnCheng. All rights reserved.
//

#import "SwingToolView.h"

@implementation SwingToolView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)setColorPanel:(DRAWING_COLOR)color
{
    switch (color) {
        case DRAWING_COLOR_RED:
        {
            [_rectangleBtn setImage:[UIImage imageNamed:@"rectangle-red"] forState:UIControlStateNormal];
            [_circleBtn setImage:[UIImage imageNamed:@"circle-red"] forState:UIControlStateNormal];
            [_lineBtn setImage:[UIImage imageNamed:@"line-red"] forState:UIControlStateNormal];
            [_arrowBtn setImage:[UIImage imageNamed:@"arrow-red"] forState:UIControlStateNormal];
            [_freelineBtn setImage:[UIImage imageNamed:@"freehand-red"] forState:UIControlStateNormal];
            [_angleBtn setImage:[UIImage imageNamed:@"angle-red"] forState:UIControlStateNormal];
            [_blastBtn setTitleColor:[UIColor colorWithHexString:@"#D60000"] forState:UIControlStateNormal];
        }
            break;
        
        case DRAWING_COLOR_WHITE:
        {
            [_rectangleBtn setImage:[UIImage imageNamed:@"rectangle-white"] forState:UIControlStateNormal];
            [_circleBtn setImage:[UIImage imageNamed:@"circle-white"] forState:UIControlStateNormal];
            [_lineBtn setImage:[UIImage imageNamed:@"line-white"] forState:UIControlStateNormal];
            [_arrowBtn setImage:[UIImage imageNamed:@"arrow-white"] forState:UIControlStateNormal];
            [_freelineBtn setImage:[UIImage imageNamed:@"freehand-white"] forState:UIControlStateNormal];
            [_angleBtn setImage:[UIImage imageNamed:@"angle-white"] forState:UIControlStateNormal];
            [_blastBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        }
            break;
        case DRAWING_COLOR_YELLOW:
        {
            [_rectangleBtn setImage:[UIImage imageNamed:@"rectangle-yellow"] forState:UIControlStateNormal];
            [_circleBtn setImage:[UIImage imageNamed:@"circle-yellow"] forState:UIControlStateNormal];
            [_lineBtn setImage:[UIImage imageNamed:@"line-yellow"] forState:UIControlStateNormal];
            [_arrowBtn setImage:[UIImage imageNamed:@"arrow-yellow"] forState:UIControlStateNormal];
            [_freelineBtn setImage:[UIImage imageNamed:@"freehand-yellow"] forState:UIControlStateNormal];
            [_angleBtn setImage:[UIImage imageNamed:@"angle-yellow"] forState:UIControlStateNormal];
            [_blastBtn setTitleColor:[UIColor colorWithHexString:@"#F9E401"] forState:UIControlStateNormal];

        }
            break;
        case DRAWING_COLOR_BLUE:
        {
            [_rectangleBtn setImage:[UIImage imageNamed:@"rectangle-blue"] forState:UIControlStateNormal];
            [_circleBtn setImage:[UIImage imageNamed:@"circle-blue"] forState:UIControlStateNormal];
            [_lineBtn setImage:[UIImage imageNamed:@"line-blue"] forState:UIControlStateNormal];
            [_arrowBtn setImage:[UIImage imageNamed:@"arrow-blue"] forState:UIControlStateNormal];
            [_freelineBtn setImage:[UIImage imageNamed:@"freehand-blue"] forState:UIControlStateNormal];
            [_angleBtn setImage:[UIImage imageNamed:@"angle-blue"] forState:UIControlStateNormal];
            [_blastBtn setTitleColor:[UIColor colorWithHexString:@"#38BFFF"] forState:UIControlStateNormal];

        }
            break;
        case DRAWING_COLOR_GREEN:
        {
            [_rectangleBtn setImage:[UIImage imageNamed:@"rectangle-green"] forState:UIControlStateNormal];
            [_circleBtn setImage:[UIImage imageNamed:@"circle-green"] forState:UIControlStateNormal];
            [_lineBtn setImage:[UIImage imageNamed:@"line-green"] forState:UIControlStateNormal];
            [_arrowBtn setImage:[UIImage imageNamed:@"arrow-green"] forState:UIControlStateNormal];
            [_freelineBtn setImage:[UIImage imageNamed:@"freehand-green"] forState:UIControlStateNormal];
            [_angleBtn setImage:[UIImage imageNamed:@"angle-green"] forState:UIControlStateNormal];
            [_blastBtn setTitleColor:[UIColor colorWithHexString:@"#4DF410"] forState:UIControlStateNormal];

        }
            break;

        default:
            break;
    }
}

@end
