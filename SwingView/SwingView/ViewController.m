//
//  ViewController.m
//  SwingView
//
//  Created by AnCheng on 4/18/16.
//  Copyright © 2016 AnCheng. All rights reserved.
//

#import "ViewController.h"
#import <pop/POP.h>
#import "SwingToolView.h"
#import "DrawBoardView.h"
#import "ReactiveCocoa/ReactiveCocoa.h"
#import "AVPlayerView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "CarouselView.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define SWINGVIEW_WIDTH     270
#define SWINGVIEW_HEIGHT    75

@interface ViewController () <DrawBoardViewDeleate ,iCarouselDataSource ,iCarouselDelegate ,UIScrollViewDelegate ,UIImagePickerControllerDelegate ,UINavigationControllerDelegate>{
    
    SwingToolView *swingView;
    
    NSInteger pastCarouselIndex1;
    NSInteger pastCarouselIndex2;
    
    NSTimer *playerTimer;

    BOOL collapseToolbar;
}

@property (nonatomic ,assign) IBOutlet UIView *recordingView;

@property (nonatomic ,assign) IBOutlet DrawBoardView *drawView1;
@property (nonatomic ,assign) IBOutlet DrawBoardView *drawView2;

@property (nonatomic ,assign) IBOutlet AVPlayerView *playerView1;
@property (nonatomic ,assign) IBOutlet AVPlayerView *playerView2;

@property (nonatomic ,assign) IBOutlet UIScrollView *scrollView1;
@property (nonatomic ,assign) IBOutlet UIScrollView *scrollView2;

@property (nonatomic ,assign) IBOutlet UIView *scrollContent1;
@property (nonatomic ,assign) IBOutlet UIView *scrollContent2;

@property (nonatomic ,assign) IBOutlet UIView *compareView1;
@property (nonatomic ,assign) IBOutlet UIView *compareView2;

@property (nonatomic ,assign) IBOutlet UIView *subView1;
@property (nonatomic ,assign) IBOutlet UIView *subView2;

@property (nonatomic ,assign) IBOutlet CarouselView *carouselView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4f];
    
    self.automaticallyAdjustsScrollViewInsets = NO;

    // add swing view
    swingView = [[[NSBundle mainBundle] loadNibNamed:@"SwingToolView" owner:self options:nil] objectAtIndex:0];
    [self.view addSubview:swingView];
    [swingView autoSetDimensionsToSize:CGSizeMake(SWINGVIEW_WIDTH, SWINGVIEW_HEIGHT)];
    _swingViewTrain = [swingView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.view withOffset:-45];
    _swingViewTop = [swingView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.view withOffset:0];
    swingView.hidden = YES;

    // notification
    [[NSNotificationCenter defaultCenter] addObserver:self // put here the view controller which has to be notified
                                             selector:@selector(orientationChanged:)
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(drawingNotification:)
                                                 name:@"stopDrawing"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(drawingNotification:)
                                                 name:@"startDrawing"
                                               object:nil];
    
    
    
    [self initUI];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    mRecorder = [[LayerRecorder alloc] init];
    _isRecording = NO;
    mRecordingUpdateTimer = nil;
    
    //Create Audio Recorder
    mAudioRecorder = [[AudioRecorder alloc] init];
    mAudioRecorder.delegate = self;
    
    //Create Mixer
    mMixer = [[AVMixer alloc] init];
    mMixer.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [_carouselView setDelegate:self];
}

- (void)initUI
{
    collapseToolbar = NO;
    
    _playbackLbl.layer.cornerRadius = 20.0f;
    _playbackLbl.layer.borderWidth = 1.0f;
    _playbackLbl.layer.borderColor = [UIColor clearColor].CGColor;
    _playbackLbl.layer.masksToBounds = YES;
    
    _smbackLbl.layer.cornerRadius = 20.0f;
    _smbackLbl.layer.borderWidth = 1.0f;
    _smbackLbl.layer.borderColor = [UIColor clearColor].CGColor;
    _smbackLbl.layer.masksToBounds = YES;
    
    _leftCommandView.hidden = YES;
    
    _colors = [[NSMutableArray alloc] initWithObjects:@(DRAWING_COLOR_RED), @(DRAWING_COLOR_RED) , @(DRAWING_COLOR_RED) , @(DRAWING_COLOR_RED) , @(DRAWING_COLOR_RED), nil];
    _shapes = [[NSMutableArray alloc] initWithObjects:@(DRAWING_TOOL_LINE), @(DRAWING_TOOL_CIRCLE) , @(DRAWING_TOOL_RECTANGLE) , @(DRAWING_TOOL_FREEDRAW) , @(DRAWING_TOOL_ANGLE), nil];
    
    [self redrawSwingTool];
    
    [self disableButton:_redoBtn];
    [self disableButton:_undoBtn];
    [self disableButton:_clearBtn];
    
    [self disableButton:_redoBtn1];
    [self disableButton:_undoBtn1];
    [self disableButton:_clearBtn1];
    
    _drawView1.delegate = self;
    _drawView2.delegate = self;
    
    [_drawView1 setShapeType:DRAWING_TOOL_LINE];
    [_drawView2 setShapeType:DRAWING_TOOL_LINE];
    [_drawView1 setShapeColor:DRAWING_COLOR_RED];
    [_drawView2 setShapeColor:DRAWING_COLOR_RED];
    
    _shapeOrderArr = [NSMutableArray new];
    _restoreShapeArr = [NSMutableArray new];
    
    [RACObserve(self, shapeOrderArr) subscribeNext:^(NSMutableArray *arr){
        
        [self enableButton:_clearBtn];
        [self enableButton:_clearBtn1];
        
        if ([arr count] > 0)
        {
            [self enableButton:_undoBtn];
            [self enableButton:_undoBtn1];
        }
        else
        {
            [self disableButton:_undoBtn];
            [self disableButton:_undoBtn1];
            if (_restoreShapeArr.count == 0)
            {
                [self disableButton:_clearBtn];
                [self disableButton:_clearBtn1];
                
            }
        }
        
    }];
    
    [RACObserve(self, restoreShapeArr) subscribeNext:^(NSMutableArray *arr){
        
        [self enableButton:_clearBtn];
        [self enableButton:_clearBtn1];
        
        if ([arr count] > 0)
        {
            [self enableButton:_redoBtn];
            [self enableButton:_redoBtn1];
            
        }
        else
        {
            [self disableButton:_redoBtn];
            [self disableButton:_redoBtn1];
            if (_shapeOrderArr.count == 0)
            {
                [self disableButton:_clearBtn];
                [self disableButton:_clearBtn1];
                
            }
        }
    }];
    
    _enableDrawing = YES;
    [self addObserver:self forKeyPath:@"enableDrawing" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    
    [_playerView1 setFileURL:[[NSBundle mainBundle] URLForResource: @"test" withExtension:@"mp4"] isAudio:NO];
    
    if ([_playerView1 ratioWidthtoHeight] < 1)
    {
        [_ratioW1 autoRemove];
        _ratioW1 = [_scrollView1 autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeHeight ofView:_scrollView1 withMultiplier:[_playerView1 ratioWidthtoHeight]];
    }
    else
    {
        [_ratioH1 autoRemove];
        _ratioH1 = [_scrollView1 autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeWidth ofView:_scrollView1 withMultiplier:1.0f / [_playerView1 ratioWidthtoHeight]];
        
    }

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    if ([keyPath isEqualToString:@"enableDrawing"]) {

        NSNumber *isEnable = [change objectForKey:NSKeyValueChangeNewKey];
        if ([isEnable boolValue])
        {
            _scrollView1.scrollEnabled = NO;
            _scrollView2.scrollEnabled = NO;
            _triangleImageView.hidden = NO;
            _drawView1.userInteractionEnabled = YES;
            _drawView2.userInteractionEnabled = YES;
        }
        else
        {
            _scrollView1.scrollEnabled = YES;
            _scrollView2.scrollEnabled = YES;
            _triangleImageView.hidden = YES;
            _drawView1.userInteractionEnabled = NO;
            _drawView2.userInteractionEnabled = NO;
        }
    }
}

- (IBAction)onSwingTool:(id)sender
{
    [self setEnableDrawing:YES];

    UIButton *button = (UIButton *)sender;
    if (_selectedIndex == button.tag - 1)
    {
        swingView.hidden = !swingView.hidden;
    }
    else
    {
        swingView.hidden = YES;
    }
    
    _selectedIndex = button.tag - 1;
    _triangleTop.constant = button.center.y - _triangleImageView.frame.size.height / 2;
    
    // add swing toolview
    CGRect buttonRect = [self.view convertRect:_triangleImageView.frame fromView:_triangleImageView.superview];
    _swingViewTop.constant = buttonRect.origin.y - SWINGVIEW_HEIGHT / 2;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGSize size = [[UIScreen mainScreen] bounds].size;
    if (button.tag == 1 && orientation != UIDeviceOrientationPortrait && fminf(size.width, size.height) <= 320){
        _swingViewTop.constant = buttonRect.origin.y - 20;
    }
    
    POPSpringAnimation *layoutAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    layoutAnimation.springSpeed = 20.0f;
    layoutAnimation.springBounciness = 15.0f;
    layoutAnimation.fromValue = @(0);
    layoutAnimation.toValue = @(-45);
    [_swingViewTrain pop_addAnimation:layoutAnimation forKey:@"swingViewTrainConstraint"];
    
    DRAWING_COLOR color = [[_colors objectAtIndex:_selectedIndex] intValue];
    DRAWING_TOOL tool = [[_shapes objectAtIndex:_selectedIndex] intValue];
    [swingView setColorPanel:color];
    
    [_drawView1 setShapeType:tool];
    [_drawView1 setShapeColor:color];
    
    [_drawView2 setShapeType:tool];
    [_drawView2 setShapeColor:color];
    
    [self redrawTriangle:color];

}

- (IBAction)onElapseTool:(id)sender
{
    swingView.hidden = YES;
    collapseToolbar = !collapseToolbar;
    
    if (collapseToolbar) {
        
        _expandBtn.hidden = NO;
        _collapseBtn.hidden = YES;
        
        POPSpringAnimation *sprintAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        sprintAnimation.velocity = [NSValue valueWithCGPoint:CGPointMake(8, 8)];
        sprintAnimation.springBounciness = 20.f;
        [self.expandBtn pop_addAnimation:sprintAnimation forKey:@"expandAnimation"];
    }
    else
    {
        _expandBtn.hidden = YES;
        _collapseBtn.hidden = NO;
        
        POPSpringAnimation *sprintAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        sprintAnimation.velocity = [NSValue valueWithCGPoint:CGPointMake(8, 8)];
        sprintAnimation.springBounciness = 20.f;
        [self.collapseBtn pop_addAnimation:sprintAnimation forKey:@"collapseAnimation"];
    }
    
    POPSpringAnimation *layoutAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    layoutAnimation.springSpeed = 20.0f;
    layoutAnimation.springBounciness = 15.0f;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (collapseToolbar)
    {
        layoutAnimation.toValue = @(0);
        _drawingView.hidden = YES;
        
        if (orientation == UIDeviceOrientationPortrait)
        {
            _reunHeight.constant = 0;
            _reunView.hidden = YES;
        }
    }
    else
    {
        layoutAnimation.toValue = @(190);
        _drawingView.hidden = NO;
        
        if (orientation == UIDeviceOrientationPortrait)
        {
            _reunHeight.constant = 72;
            _reunView.hidden = NO;
        }
    }
    
    [_drawingHeight pop_addAnimation:layoutAnimation forKey:@"drawtoolHeightConstraint"];
}

- (IBAction)onSwingPanel:(id)sender
{
    
    UIButton *button = (UIButton *)sender;
    DRAWING_TOOL selectTool;
    switch (button.tag) {
        case 1:
            selectTool = DRAWING_TOOL_RECTANGLE;
            break;
        case 2:
            selectTool = DRAWING_TOOL_CIRCLE;
            break;
        case 3:
            selectTool = DRAWING_TOOL_LINE;
            break;
        case 4:
            selectTool = DRAWING_TOOL_FREEDRAW;
            break;
        case 5:
            selectTool = DRAWING_TOOL_FREEDRAW;
            break;
        case 6:
            selectTool = DRAWING_TOOL_ANGLE;
            break;
        case 7:
            selectTool = DRAWING_TOOL_BLAST;
            break;
        case 8:
            selectTool = DRAWING_TOOL_AUTOLINE;
            break;
        default:
            break;
    }
    
    [_shapes replaceObjectAtIndex:_selectedIndex withObject:@(selectTool)];
    [self redrawSwingTool];
    
    [_drawView1 setShapeType:selectTool];
    [_drawView2 setShapeType:selectTool];

    swingView.hidden = YES;
}

- (IBAction)onColorPanel:(id)sender
{
    UIButton *button = (UIButton *)sender;
    DRAWING_COLOR selectColor;
    switch (button.tag) {
        case 1:
            selectColor = DRAWING_COLOR_RED;
            break;
        case 2:
            selectColor = DRAWING_COLOR_YELLOW;
            break;
        case 3:
            selectColor = DRAWING_COLOR_GREEN;
            break;
        case 4:
            selectColor = DRAWING_COLOR_BLUE;
            break;
        case 5:
            selectColor = DRAWING_COLOR_WHITE;
            break;
        default:
            break;
    }
    
    [_colors replaceObjectAtIndex:_selectedIndex withObject:@(selectColor)];
    [self redrawTriangle:selectColor];
    [self redrawSwingTool];
    
    [_drawView1 setShapeColor:selectColor];
    [_drawView2 setShapeColor:selectColor];

    swingView.hidden = YES;

}

- (IBAction)onRedo:(id)sender
{

    NSMutableArray *shapeOrderArr = [self mutableArrayValueForKey:@keypath(self, shapeOrderArr)];
    NSMutableArray *restoreShapeArr = [self mutableArrayValueForKey:@keypath(self, restoreShapeArr)];

    NSDictionary *dic = [restoreShapeArr lastObject];
    if ([dic[@"panel"] intValue] == 1)
    {
        [_drawView1 addShape:dic[@"shape"]];
        [shapeOrderArr addObject:@(1)];
    }
    else
    {
        [_drawView2 addShape:dic[@"shape"]];
        [shapeOrderArr addObject:@(2)];

    }
    
    [restoreShapeArr removeLastObject];
}

- (IBAction)onUndo:(id)sender
{
    NSMutableArray *shapeOrderArr = [self mutableArrayValueForKey:@keypath(self, shapeOrderArr)];
    NSMutableArray *restoreShapeArr = [self mutableArrayValueForKey:@keypath(self, restoreShapeArr)];

    int panelNum = [[shapeOrderArr lastObject] intValue];
    
    if (panelNum == 1)
    {
        if ([_drawView1 getLastShape] != nil)
        {
            [restoreShapeArr addObject:@{@"panel" : @(1) ,@"shape" : [_drawView1 getLastShape]}];
            [_drawView1 deleteLastShape];
        }
    }
    else
    {
        if ([_drawView2 getLastShape] != nil)
        {
            [restoreShapeArr addObject:@{@"panel" : @(2) ,@"shape" : [_drawView2 getLastShape]}];
            [_drawView2 deleteLastShape];
        }
    }
    
    [shapeOrderArr removeLastObject];
}

- (IBAction)onClear:(id)sender
{
    NSMutableArray *shapeOrderArr = [self mutableArrayValueForKey:@keypath(self, shapeOrderArr)];
    NSMutableArray *restoreShapeArr = [self mutableArrayValueForKey:@keypath(self, restoreShapeArr)];
    [shapeOrderArr removeAllObjects];
    [restoreShapeArr removeAllObjects];
    
    [_drawView1 clearBoard];
    [_drawView2 clearBoard];
}

- (IBAction)onPlay:(id)sender
{
    UIButton *playBtn = (UIButton *)sender;
    playBtn.selected = !playBtn.selected;
    if (playBtn.selected)
    {
        [_playerView1 play];
        if (_playerView2.player != nil)
            [_playerView2 play];
        
        if (_motionBtn.selected)
        {
            [_playerView1.player setRate:0.25];
            [_playerView2.player setRate:0.25];
        }
        else
        {
            [_playerView1.player setRate:1];
            [_playerView2.player setRate:1];
        }
        
        playerTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
        
    }
    else
    {
        [_playerView1 pause];
        if (_playerView2.player != nil)
            [_playerView2 stop];
        
        [playerTimer invalidate];
    }
}

- (IBAction)onSlowMotion:(id)sender
{
    UIButton *motionBtn = (UIButton *)sender;
    motionBtn.selected = !motionBtn.selected;
    
    if (motionBtn.selected)
    {
        [motionBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    }
    else
    {
        [motionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    
    if (_playBtn.isSelected)
    {
        if (motionBtn.selected)
        {
            [_playerView1.player setRate:0.25];
            [_playerView2.player setRate:0.25];
        }
        else
        {
            [_playerView1.player setRate:1];
            [_playerView2.player setRate:1];
        }
    }
    
}

- (IBAction)onCompare:(id)sender
{
    UIBarButtonItem *item = (UIBarButtonItem *)sender;
    
    if ([item.title isEqualToString:@"Compare"])
    {
        item.title = @"Cancel";
        _compareView1.hidden = NO;
        _compareView2.hidden = NO;
        
        _subView2.hidden = NO;
        _mode = PANEL_TWOMODE;
        
        if (_playerView2.player == nil)
        {
            // only change for play view 1
            // only add for play view 2
            
            [_changeBtn2 setTitle:@"Add" forState:UIControlStateNormal];
            [_removeBtn2 setHidden:YES];

        }
        else
        {
            [_changeBtn2 setTitle:@"Change" forState:UIControlStateNormal];
            [_removeBtn2 setHidden:NO];
        }

    }
    else
    {
        item.title = @"Compare";
        _compareView1.hidden = YES;
        _compareView2.hidden = YES;
        
        if (_playerView2.player == nil)
        {
            _mode = PANEL_ONEMODE;
            _subView2.hidden = YES;

        }
        else
        {
            _mode = PANEL_TWOMODE;
            _subView2.hidden = NO;

        }
    }

    [self setUpPanel];

}

- (IBAction)onChange:(id)sender
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    [imagePicker.view setFrame:CGRectMake(0, 80, 320, 350)];
    [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    imagePicker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
    
}

- (IBAction)onRemove:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    [_playerView2 uninitPlayer];
    _playerView2.player = nil;
    
    if (button.tag == 1)
    {
        // remove video from player 1
        [_playerView1 setFileURL:_playerView2.url isAudio:NO];
    }
    
    _mode = PANEL_ONEMODE;
    [self setUpPanel];
    [self backtoCancel];
    [self onClear:nil];

    [_carouselView setMode:_mode];

}

- (IBAction)onRecord:(id)sender
{
    // Record Code
    if (_isRecording)
    {
        [mRecorder stopRecording];
        [mAudioRecorder stopRecording];
        
        if (mRecordingUpdateTimer != nil) {
            [mRecordingUpdateTimer invalidate];
            mRecordingUpdateTimer = nil;
        }
        
    } else {

        [mRecorder setLayer:_recordingView.layer];
        [mRecorder startRecording];
        [mAudioRecorder startRecording];
        
        mRecordingUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onRecordingTimer:) userInfo:nil repeats:YES];
        
    }
    
    _isRecording = !_isRecording ;
    
}

- (void)onRecordingTimer:(id)sender
{
    self.recordButton.selected = !self.recordButton.selected;
    self.recordButton.highlighted = !self.recordButton.highlighted;
}

- (void)backtoCancel
{
    [_compareItem setTitle:@"Compare"];
    _compareView1.hidden = YES;
    _compareView2.hidden = YES;
    
    if (_playerView2.player == nil)
    {
        _mode = PANEL_ONEMODE;
        _subView2.hidden = YES;
        
    }
    else
    {
        _mode = PANEL_TWOMODE;
        _subView2.hidden = NO;
        
    }
}

- (void)setUpPanel
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation] ;

    [_ratioHeight autoRemove];
    [_ratioWidth autoRemove];
    
    if (_mode == PANEL_ONEMODE)
    {
        _ratioWidth = [_subView1 autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeWidth ofView:_subView1.superview withMultiplier:1.0f];
        _ratioHeight = [_subView1 autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeHeight ofView:_subView1.superview withMultiplier:1.0f];

    }
    else if (_mode == PANEL_TWOMODE && orientation == UIDeviceOrientationPortrait)
    {
        _ratioWidth = [_subView1 autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeWidth ofView:_subView1.superview withMultiplier:1.0f];
        _ratioHeight = [_subView1 autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeHeight ofView:_subView1.superview withMultiplier:0.5f];

    }
    else if (_mode == PANEL_TWOMODE && (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight))
    {
        _ratioWidth = [_subView1 autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeWidth ofView:_subView1.superview withMultiplier:0.5f];
        _ratioHeight = [_subView1 autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeHeight ofView:_subView1.superview withMultiplier:1.0f];

    }
    
}

- (void)orientationChanged:(NSNotification *)notification{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation] ;
    
    swingView.hidden = YES;
    
    [self setUpPanel];

    //do stuff
    if (orientation == UIDeviceOrientationPortrait)
    {
        
        for (UIButton *button in _commandButtons)
            button.hidden = NO;
        
        _leftCommandView.hidden = YES;

        if (collapseToolbar)
        {
            _reunHeight.constant = 0;
            _reunView.hidden = YES;
            
        }
        else
        {
            _reunHeight.constant = 71;
            _reunView.hidden = NO;
            
        }
        
    }
    else if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
        
        for (UIButton *button in _commandButtons)
            button.hidden = YES;
        
        _leftCommandView.hidden = NO;
        
    }
    
    [_carouselView reloadView];
    [_drawView1 setNeedsDisplay];
    [_drawView2 setNeedsDisplay];
    
}

- (void)redrawSwingTool
{
    for (UIButton *button in _shapeButtons)
    {
        DRAWING_COLOR color = [[_colors objectAtIndex:button.tag - 1] intValue];
        DRAWING_TOOL tool = [[_shapes objectAtIndex:button.tag - 1] intValue];
        
        NSString *imageName = @"";
        switch (tool) {
            case DRAWING_TOOL_RECTANGLE:
                imageName = [imageName stringByAppendingString:@"rectangle"];
                break;
            case DRAWING_TOOL_CIRCLE:
                imageName = [imageName stringByAppendingString:@"circle"];
                break;
            case DRAWING_TOOL_LINE:
                imageName = [imageName stringByAppendingString:@"line"];
                break;
            case DRAWING_TOOL_ANGLE:
                imageName = [imageName stringByAppendingString:@"angle"];
                break;
            case DRAWING_TOOL_FREEDRAW:
                imageName = [imageName stringByAppendingString:@"freehand"];
                break;
            case DRAWING_TOOL_ARROW:
                imageName = [imageName stringByAppendingString:@"arrow"];
                break;
            default:
                break;
        }
        
        imageName = [imageName stringByAppendingString:@"-"];

        switch (color) {
            case DRAWING_COLOR_RED:
                imageName = [imageName stringByAppendingString:@"red"];
                break;
            case DRAWING_COLOR_WHITE:
                imageName = [imageName stringByAppendingString:@"white"];
                break;
            case DRAWING_COLOR_YELLOW:
                imageName = [imageName stringByAppendingString:@"yellow"];
                break;
            case DRAWING_COLOR_GREEN:
                imageName = [imageName stringByAppendingString:@"green"];
                break;
            case DRAWING_COLOR_BLUE:
                imageName = [imageName stringByAppendingString:@"blue"];
                break;
            default:
                break;
        }
        
        if (tool == DRAWING_TOOL_BLAST || tool == DRAWING_TOOL_AUTOLINE)
        {
            [button setImage:nil forState:UIControlStateNormal];
            if (tool == DRAWING_TOOL_BLAST)
                [button setTitle:@"BL" forState:UIControlStateNormal];
            else
                [button setTitle:@"AL" forState:UIControlStateNormal];

            switch (color) {
                case DRAWING_COLOR_RED:
                    [button setTitleColor:[UIColor colorWithHexString:@"#D60000"] forState:UIControlStateNormal];
                    break;
                case DRAWING_COLOR_WHITE:
                    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                    break;
                case DRAWING_COLOR_YELLOW:
                    [button setTitleColor:[UIColor colorWithHexString:@"#F9E401"] forState:UIControlStateNormal];
                    break;
                case DRAWING_COLOR_GREEN:
                    [button setTitleColor:[UIColor colorWithHexString:@"#4DF410"] forState:UIControlStateNormal];
                    break;
                case DRAWING_COLOR_BLUE:
                    [button setTitleColor:[UIColor colorWithHexString:@"#38BFFF"] forState:UIControlStateNormal];
                    break;
                default:
                    break;
            }
        }
        else
            [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    }
}

- (void)redrawTriangle:(DRAWING_COLOR)color
{
    switch (color) {
        case DRAWING_COLOR_RED:
            [_triangleImageView setImage:[UIImage imageNamed:@"triangle-red"]];
            break;
        case DRAWING_COLOR_WHITE:
            [_triangleImageView setImage:[UIImage imageNamed:@"triangle-white"]];
            break;
        case DRAWING_COLOR_YELLOW:
            [_triangleImageView setImage:[UIImage imageNamed:@"triangle-yellow"]];
            break;
        case DRAWING_COLOR_GREEN:
            [_triangleImageView setImage:[UIImage imageNamed:@"triangle-green"]];
            break;
        case DRAWING_COLOR_BLUE:
            [_triangleImageView setImage:[UIImage imageNamed:@"triangle-blue"]];
            break;
        default:
            break;
    }
}

- (void)enableButton:(UIButton *)button
{
    button.enabled = YES;
    button.alpha = 1.0f;
}

- (void)disableButton:(UIButton *)button
{
    button.enabled = NO;
    button.alpha = 0.5f;
}

#pragma mark - DrawBoardViewDeleate
- (void)finishDraw:(DrawBoardView *)aDrawBoardView
{
    NSMutableArray *shapeOrderArr = [self mutableArrayValueForKey:@keypath(self, shapeOrderArr)];
    
    if (aDrawBoardView == _drawView1)
    {
        [shapeOrderArr addObject:@(1)];

    }
    else
    {
        [shapeOrderArr addObject:@(2)];

    }
    
    [_restoreShapeArr removeAllObjects];
}

#pragma mark - iCarouselDataSource
- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    
    float width = carousel.frame.size.width;
    return (NSInteger)(width / 15.0f) - 1;

}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(nullable UIView *)view
{
    UIView *itemView = view;
    if (!itemView)
    {
        itemView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 44)];
        itemView.backgroundColor = [UIColor clearColor];
        
        UIView *gapView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 44)];
        if (index % 2 == 1)
        {
            gapView.frame = CGRectMake(0, 0, 2, 44);
        }
        else
        {
            gapView.frame = CGRectMake(0, 5, 2, 34);

        }
        gapView.backgroundColor = [UIColor clearColor];
        gapView.tag = 1;
        [itemView addSubview:gapView];
    }
    
    UIView *gapView = [itemView viewWithTag:1];
    gapView.backgroundColor = (index == 1) ? [UIColor redColor] : [UIColor whiteColor];
    
    return itemView;

}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{

    switch (option)
    {
        case iCarouselOptionFadeMin:
            return -0.0;
        case iCarouselOptionFadeMax:
            return 0.0;
        case iCarouselOptionFadeRange:
            return carousel.frame.size.width / 20;
        case iCarouselOptionArc:
            return  M_PI  * 0.4;
        case iCarouselOptionRadius:
            return carousel.frame.size.width;

        default:
            return value;
    }
    
    return value;
}

- (CATransform3D)carousel:(iCarousel *)carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform
{
    return CATransform3DIdentity;
}

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel
{
    if (carousel.currentItemIndex == 0) return;
    
    NSInteger di;
    if (carousel == _carouselView.carousel1)
        di = carousel.currentItemIndex - pastCarouselIndex1;
    else
        di = carousel.currentItemIndex - pastCarouselIndex2;
    
    if (di > 2)
        di = 2;
    if (di < -2)
        di = -2;
    
    if (carousel == _carouselView.carousel1)
    {
        [_playerView1 stepByCount:(int)di];
        [_carouselView setProgress:_playerView1.currentTime / _playerView1.duration view:YES];
        
        if (!_carouselView.isHalf){
            
            [_playerView2 stepByCount:(int)di];
            [_carouselView setProgress:_playerView2.currentTime / _playerView2.duration view:NO];
        }

        pastCarouselIndex1 = carousel.currentItemIndex;

    }
    else
    {
        [_playerView2 stepByCount:(int)di];
        [_carouselView setProgress:_playerView2.currentTime / _playerView2.duration view:NO];
        pastCarouselIndex2 = carousel.currentItemIndex;

    }

}

- (void)carouselWillBeginDragging:(iCarousel *)carousel
{
    if (carousel == _carouselView.carousel1)
        pastCarouselIndex1 = carousel.currentItemIndex;
    else
        pastCarouselIndex2 = carousel.currentItemIndex;
}

#pragma mark - UIScrollViewDelegate
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    if (scrollView == _scrollView1)
        return _scrollContent1;
    else
        return _scrollContent2;

}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale
{
    if (_scrollView1.zoomScale == 1.0 && _scrollView2.zoomScale == 1.0)
    {
        //_enableDrawing = YES;
        [self setEnableDrawing:YES];
    }
    else
    {
        //_enableDrawing = NO;
        [self setEnableDrawing:NO];
    }
}

- (void) drawingNotification:(NSNotification *) notification
{
    if ([notification.name isEqualToString:@"startDrawing"])
    {
        // hide all views except drawing view
        self.navigationController.navigationBarHidden = YES;
        _carouselView.hidden = YES;
        _rightToolView.hidden = YES;
        _leftToolView.hidden = YES;
    }
    else if ([notification.name isEqualToString:@"stopDrawing"])
    {
        // show all views except drawing view
        self.navigationController.navigationBarHidden = NO;
        _carouselView.hidden = NO;
        _rightToolView.hidden = NO;
        _leftToolView.hidden = NO;

    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:^(void){
        
        NSURL *videoUrl = [info objectForKey:UIImagePickerControllerReferenceURL];
        [_playerView2 setFileURL:videoUrl isAudio:NO];
        
        [_ratioW2 autoRemove];
        [_ratioH2 autoRemove];
        
        if ([_playerView2 ratioWidthtoHeight] < 1)
        {
        
            _ratioH2 = [_scrollView2 autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeHeight ofView:_scrollView2.superview withMultiplier:1];
            _ratioW2 = [_scrollView2 autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeHeight ofView:_scrollView2.superview withMultiplier:[_playerView2 ratioWidthtoHeight]];
            
        }
        else
        {
            _ratioW2 = [_scrollView2 autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeWidth ofView:_scrollView2.superview withMultiplier:1];
            _ratioH2 = [_scrollView2 autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeWidth ofView:_scrollView2.superview withMultiplier:1.0f / [_playerView2 ratioWidthtoHeight]];
            
        }
        
        _mode = PANEL_TWOMODE;
        [self setUpPanel];
        
        [self backtoCancel];
        [self onClear:nil];
        [_carouselView setMode:_mode];
    }];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateProgress
{
    [_carouselView setProgress:_playerView1.currentTime / _playerView1.duration view:YES];
    if (_playerView2.player != nil)
        [_carouselView setProgress:_playerView2.currentTime / _playerView2.duration view:NO];
    
    if ([_playerView1 isPause])
    {
        [_carouselView setProgress:1 view:YES];
    }
    if ([_playerView2 isPause])
    {
        [_carouselView setProgress:1 view:NO];
    }
    
    if ((_mode == PANEL_ONEMODE && [_playerView1 isPause]) || (_mode == PANEL_TWOMODE && [_playerView1 isPause] && [_playerView2 isPause]))
    {
        [self onPlay:_playBtn];

    }
}

#pragma mark - Audio Recording
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    [mRecordingUpdateTimer invalidate];
    mRecordingUpdateTimer = nil;
    self.recordButton.selected = NO;
    //todo
    
    //Start Mixing
    [SVProgressHUD showWithStatus:@"Processing..."];
    [mMixer startMixingWithVideoPath:[LayerRecorder defaultOutputPath] withAudioPath:[AudioRecorder defaultOutputPath]];
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    [mRecordingUpdateTimer invalidate];
    mRecordingUpdateTimer = nil;
    self.recordButton.selected = NO;
    
    [self performSelectorOnMainThread:@selector(onBack:) withObject:nil waitUntilDone:YES];
}

- (void)onBack:(NSString *)filePath
{
    //    [self.navigationController popViewControllerAnimated:YES];
    NSLog(@"error happened !");
    
}

#pragma mark - AVMixerDelegate
- (void)mixDidFinished:(AVMixer *)aMixer
{
    [self performSelectorOnMainThread:@selector(didMixProc:) withObject:nil waitUntilDone:YES];
    
}

- (void)didMixProc:(id)sender {
    [self performSelector:@selector(onSaveAndBack:) withObject:nil afterDelay:1.0f];
}

- (void)onSaveAndBack:(NSString *)filePath
{
    
    [SVProgressHUD dismiss];
    
    NSURL *movieURL = [NSURL fileURLWithPath:[AVMixer defaultOutputPath]];
    
    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:movieURL
                                completionBlock:^(NSURL *assetURL, NSError *error){/*notify of completion*/}];

    
}

@end
