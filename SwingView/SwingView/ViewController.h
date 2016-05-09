//
//  ViewController.h
//  SwingView
//
//  Created by AnCheng on 4/18/16.
//  Copyright © 2016 AnCheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LayerRecorder.h"
#import "AudioRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import "AVMixer.h"

typedef enum _tagPANAL_TYPE {
    PANEL_ONEMODE = 0,
    PANEL_TWOMODE
} PANAL_TYPE;

@interface ViewController : UIViewController <AVAudioRecorderDelegate, AVMixerDelegate>
{
    LayerRecorder *     mRecorder;
    AudioRecorder *     mAudioRecorder;
    AVMixer *           mMixer;
    NSTimer *           mRecordingUpdateTimer;
    BOOL                _isRecording;
    
}

@property (nonatomic ,assign) IBOutlet UIImageView *triangleImageView;
@property (nonatomic ,assign) IBOutlet UIView *rightToolView;
@property (nonatomic ,assign) IBOutlet UIView *leftToolView;

@property (nonatomic, strong) IBOutletCollection(UIButton) NSArray *commandButtons;
@property (nonatomic, strong) IBOutletCollection(UIButton) NSArray *shapeButtons;

@property (nonatomic ,assign) IBOutlet NSLayoutConstraint *drawingHeight;
@property (nonatomic ,assign) IBOutlet NSLayoutConstraint *reunHeight;
@property (nonatomic ,assign) IBOutlet NSLayoutConstraint *triangleTop;

@property (nonatomic ,strong) IBOutlet NSLayoutConstraint *ratioW1;
@property (nonatomic ,strong) IBOutlet NSLayoutConstraint *ratioW2;
@property (nonatomic ,strong) IBOutlet NSLayoutConstraint *ratioH1;
@property (nonatomic ,strong) IBOutlet NSLayoutConstraint *ratioH2;

@property (nonatomic ,strong) IBOutlet NSLayoutConstraint *ratioWidth;
@property (nonatomic ,strong) IBOutlet NSLayoutConstraint *ratioHeight;

@property (nonatomic ,strong)  NSLayoutConstraint *swingViewTop;
@property (nonatomic ,strong)  NSLayoutConstraint *swingViewTrain;

@property (nonatomic ,assign) IBOutlet UIView *drawingView;
@property (nonatomic ,assign) IBOutlet UIView *reunView;

@property (nonatomic ,assign) IBOutlet UIButton *collapseBtn;
@property (nonatomic ,assign) IBOutlet UIButton *expandBtn;

@property (nonatomic ,assign) IBOutlet UILabel *smbackLbl;
@property (nonatomic ,assign) IBOutlet UILabel *playbackLbl;

@property (nonatomic ,assign) IBOutlet UIView *leftCommandView;

@property (nonatomic ,assign) IBOutlet UIButton *clearBtn;
@property (nonatomic ,assign) IBOutlet UIButton *redoBtn;
@property (nonatomic ,assign) IBOutlet UIButton *undoBtn;

@property (nonatomic ,assign) IBOutlet UIButton *clearBtn1;
@property (nonatomic ,assign) IBOutlet UIButton *redoBtn1;
@property (nonatomic ,assign) IBOutlet UIButton *undoBtn1;

@property (nonatomic ,assign) IBOutlet UIButton *changeBtn1;
@property (nonatomic ,assign) IBOutlet UIButton *changeBtn2;
@property (nonatomic ,assign) IBOutlet UIButton *removeBtn1;
@property (nonatomic ,assign) IBOutlet UIButton *removeBtn2;

@property (nonatomic ,assign) IBOutlet UIButton *playBtn;
@property (nonatomic ,assign) IBOutlet UIButton *motionBtn;
@property (nonatomic ,assign) IBOutlet UIButton *recordButton;

@property (nonatomic ,assign) IBOutlet UIBarButtonItem *compareItem;

@property (nonatomic ,strong) NSMutableArray *colors;
@property (nonatomic ,strong) NSMutableArray *shapes;
@property (nonatomic) NSInteger selectedIndex;

@property (nonatomic ,strong) NSMutableArray *shapeOrderArr;
@property (nonatomic ,strong) NSMutableArray *restoreShapeArr;
@property (nonatomic) BOOL enableDrawing;

@property (nonatomic) PANAL_TYPE mode;

- (IBAction)onSwingTool:(id)sender;
- (IBAction)onElapseTool:(id)sender;

- (IBAction)onSwingPanel:(id)sender;
- (IBAction)onColorPanel:(id)sender;

- (IBAction)onRedo:(id)sender;
- (IBAction)onUndo:(id)sender;
- (IBAction)onClear:(id)sender;

- (IBAction)onPlay:(id)sender;
- (IBAction)onSlowMotion:(id)sender;

- (IBAction)onCompare:(id)sender;
- (IBAction)onChange:(id)sender;
- (IBAction)onRemove:(id)sender;
- (IBAction)onRecord:(id)sender;

@end
