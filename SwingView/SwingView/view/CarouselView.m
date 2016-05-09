//
//  CarouselView.m
//  SwingView
//
//  Created by AnCheng on 4/30/16.
//  Copyright © 2016 AnCheng. All rights reserved.
//

#import "CarouselView.h"

@implementation CarouselView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self setUp];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        
        [self setUp];
    }
    
    return self;
}

- (void)setUp
{
    self.backgroundColor = [UIColor clearColor];
    
    UIView *backView = [[UIView alloc] init];
    backView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
    [self addSubview:backView];
    [backView autoPinEdgesToSuperviewEdges];
    
    _carousel1 = [[iCarousel alloc] init];
    _carousel2 = [[iCarousel alloc] init];
    _carousel1.type = iCarouselTypeCylinder;
    _carousel2.type = iCarouselTypeCylinder;

    _carousel1.clipsToBounds = YES;
    _carousel2.clipsToBounds = YES;
    
    _carousel1.backgroundColor = [UIColor clearColor];
    _carousel2.backgroundColor = [UIColor clearColor];
    
    _resizeBtn = [[UIButton alloc] init];
    [_resizeBtn setImage:[UIImage imageNamed:@"chain_white_icon"] forState:UIControlStateNormal];
    
    [self addSubview:_carousel1];
    [self addSubview:_carousel2];
    [self addSubview:_resizeBtn];
    
    _progress1 = [UIProgressView new];
    _progress1.progress = 0.0;
    _progress1.tintColor = [UIColor whiteColor];
    _progress1.trackTintColor = [UIColor clearColor];
    _progress2 = [UIProgressView new];
    _progress2.progress = 0.5;
    _progress2.tintColor = [UIColor whiteColor];
    _progress2.trackTintColor = [UIColor clearColor];
    
    [self addSubview:_progress1];
    [self addSubview:_progress2];
    
    // add constraint

    [_carousel1 autoConstrainAttribute:ALAttributeLeading toAttribute:ALAttributeLeading ofView:self];
    [_carousel1 autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeTop ofView:self];
    [_carousel1 autoConstrainAttribute:ALAttributeBottom toAttribute:ALAttributeBottom ofView:self];

    _carouselWidth = [_carousel1 autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
    
    [_resizeBtn autoSetDimension:ALDimensionWidth toSize:40.0f];
    [_resizeBtn autoSetDimension:ALDimensionHeight toSize:40.0f];
    [_resizeBtn setContentEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    [_resizeBtn autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [_resizeBtn autoConstrainAttribute:ALAttributeLeading toAttribute:ALAttributeTrailing ofView:_carousel1];

    [_resizeBtn addTarget:self action:@selector(changeDimention:) forControlEvents: UIControlEventTouchUpInside];
    
    [_carousel2 autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:_carousel1];
    [_carousel2 autoConstrainAttribute:ALAttributeLeading toAttribute:ALAttributeTrailing ofView:_resizeBtn];
    [_carousel2 autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeTop ofView:self];
    [_carousel2 autoConstrainAttribute:ALAttributeBottom toAttribute:ALAttributeBottom ofView:self];
    
    [_progress1 autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:_carousel1];
    [_progress1 autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:_carousel1];
    [_progress1 autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:_carousel1];
    
    [_progress2 autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:_progress1];
    _progress2Leading = [_progress2 autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:_carousel2];
    _progress2Bottom = [_progress2 autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
}

- (void)setMode:(PANAL_TYPE)mode
{
    [_carouselWidth autoRemove];
    
    [_progress2Leading autoRemove];
    [_progress2Bottom autoRemove];

    
    if (mode == PANEL_ONEMODE)
    {
        _carouselWidth = [_carousel1 autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];

        _progress2Leading = [_progress2 autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:_carousel2];
        _progress2Bottom = [_progress2 autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
    }
    else
    {
        _carouselWidth = [_carousel1 autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withOffset:-40.0f];
        _isHalf = NO;
        
        _progress2Leading = [_progress2 autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:_carousel1];
        _progress2Bottom = [_progress2 autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self withOffset:-3.0f];
        
        _progress2.progress = 0.0f;
    }
    
    [self layoutIfNeeded];
    [self reloadView];

}

- (void)setDelegate:(id)delegate
{
    _carousel1.delegate = delegate;
    _carousel1.dataSource = delegate;
    
    _carousel2.delegate = delegate;
    _carousel2.dataSource = delegate;

}

- (void)changeDimention:(id)sender
{
    _isHalf = !_isHalf;
    [_carouselWidth autoRemove];
    [_progress2Leading autoRemove];
    [_progress2Bottom autoRemove];

    if (_isHalf)
    {
        _carouselWidth = [_carousel1 autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.5f];
        _carouselWidth.constant = -20.0f;
        
        _progress2Leading = [_progress2 autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:_carousel2];
        _progress2Bottom = [_progress2 autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
    }
    else
    {
        _carouselWidth = [_carousel1 autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withOffset:-40.0f];

        _progress2Leading = [_progress2 autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:_carousel1];
        _progress2Bottom = [_progress2 autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self withOffset:-3.0f];
    }
    
    [self layoutIfNeeded];
    [self reloadView];

}

- (void)reloadView{
    
    [_carousel1 reloadData];
    [_carousel2 reloadData];
}

- (void)setProgress:(float)progress view:(BOOL)isFirst
{
    if (isFirst)
    {
        _progress1.progress = progress;
    }
    else
    {
        _progress2.progress = progress;

    }
}

@end
