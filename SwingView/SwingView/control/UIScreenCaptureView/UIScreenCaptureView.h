//
//  UIScreenCaptureView.h
//  UIScreenCaptureView
//
//  v1.0 Created by Tom Markel on 7/18/12.
//  v1.1 Updated by Tom Markel on 8/21/2012 for bug fix to resolve UIView animation contention issues and use new method of triggering screen snapshots.
//  v2.0 Updated 10/10/12 to fix recordingFinished method warning
//  v2.2 Updated 12/05/12 to fix iOS6 AVAssetWriter changes
//  v2.3 Updated 12/12/12 to use quartzCore screen snapshot function
//  v3.0 Updated 05/14/12 to fix to use bounds self.bounds.size instead of frame self.frame.size
//  v4.0 Updated 10/11/13 to use new snapshot API on iOS7
//  v4.1 Updated 10/11/13 - fixed a bug with using new snapshot API on iOS7: color palette was wrong
//  v4.2 Updated 08/21/14 - added ability to capture fullscreen application window with or without the status bar.  So can capture view (by default), fullscreen with status bar or fullscreen with no status bar.
//  v4.2.1 Updates to not use options for more recent iOS versions - this fixes retina display problems
//  v4.3 Updated 09/16/2014 - added ability to include audio to the recording.  Global sounds - app, mic etc...
//       Use new includeAudio:TRUE to include audio otherwise default is to not include audio
//       If audio is included the video file is a .mov QuickTime Movie file
//       If audio is not included, the video file is .mp4 file
//  v4.3.1 Updated 10/11/2014 - ARC, iOS8+
//  v4.4 Updated 03/23/2015 - fix for retina on iPhone
//  v4.4.2 Updated 04/14/2015 - fix for screenshot for retina
//  v4.4.3 Updated 04/23/2015 - fix random crashes by switching from NSThread to GCD
//  v4.4.4 Updated 07/25/2015 - fixed broken method: startRecordingViewForTimePeriod
//  v4.4.5 Updated 08/20/2015 - added new static method: takeScreenSnapshotAndSave
//  v4.4.6 Updated 08/24/2015 - added optional method for getting photos Asset URL to UIScreenCaptureViewDelegate:
//                            - (void) assetURL:(NSURL *)assetURL error:(NSError *)error;
//  v4.5   Updated 10/05/2015 - fixed OTScreenshotHelper for iOS8+
//  v4.5.5 Updated 12/22/2015 - fixed compile provisioning error
//
//  Copyright (c) 2012-2014 MarkelSoft, Inc. All rights reserved.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MPMediaQuery.h>
#import <MediaPlayer/MPMediaPlaylist.h>
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>

#import "OTScreenshotHelper.h"
#import "SystemUtilities.h"

/**
 * Delegate protocol.  Implement this if you want to receive a notification when the
 * view completes a recording.
 *
 * When a recording is completed, the ScreenCaptureView will notify the delegate, passing
 * it the path to the created recording file if the recording was successful, or a value
 * of nil if the recording failed/could not be saved.
 */
@protocol UIScreenCaptureViewDelegate <NSObject>
- (void) recordingFinished:(NSURL *)outputPathOrNil;
@optional
- (void) assetURL:(NSURL *)assetURL error:(NSError *)error;
@end

/**
 * UIScreenCaptureView, a UIView subclass that periodically samples its current display
 * and stores it as a UIImage available through the 'currentScreen' property.  The
 * sample/update rate can be configured (within reason) by setting the 'frameRate'
 * property.
 *
 * This class can also be used to record real-time video of its subviews, using the
 * 'startRecording' and 'stopRecording' methods.  A new recording will overwrite any
 * previously made recording file, so if you want to create multiple recordings per
 * session (or across multiple sessions) then it is your responsibility to copy/back-up
 * the recording output file after each session.
 *
 * To use this class, you must link against the following frameworks:
 *
 *  - AssetsLibrary
 *  - AVFoundation
 *  - CoreGraphics
 *  - CoreMedia
 *  - CoreVideo
 *  - QuartzCore
 *  - MediaPlayer
 *
 */

@interface UIScreenCaptureView : UIView <UIScreenCaptureViewDelegate> {
    
    //video writing
    AVAssetWriter * videoWriter;
    AVAssetWriterInput * videoWriterInput;
    AVAssetWriterInputPixelBufferAdaptor * avAdaptor;
    AVAudioRecorder * audioRecorder;
    MPMoviePlayerViewController * myVideoPlayer;
    
    NSString * videoOutPath;
    NSString * audioOutPath;
    
    NSDate * startedAt;
    NSString * __weak outputName;
    void * bitmapData;
    
    NSTimer * recordingTimer;
    int timerTotalSeconds;
    int timerElapsedSeconds;
    
    UIViewController * _viewParent;
    UIViewController * _parent;
    
    UIView * savedView;
    UIView * savedViewParent;
    CGRect savedViewFrame;
    UIScreenCaptureView * recordingView;
    
    BOOL _checkRunning;
    BOOL _recording;               // recording state
    BOOL _timedRecording;          // timed recoding state
    BOOL _verbose;                 // verbose debug
    BOOL _useOldSnapshot;          // use old (pre iOS7) capture
    BOOL _runSnapshotInBackground; // run snapshot on background  thread
    
    BOOL _includeAudio;
    
    BOOL _snapshotThreadRunning;
    BOOL _success;
    BOOL _completed;
    
    BOOL _fullScreenWithNoStatusBar;
    BOOL _fullScreenWithStatusBar;
}

// for accessing the current screen and adjusting the capture rate, etc.
@property(strong, retain) UIImage * currentScreen;
@property(assign) float frameRate;
@property(weak) NSString * outputName;
@property(nonatomic, weak) id<UIScreenCaptureViewDelegate> delegate;

// static method to take a snapshot of the application screen (with status bar)...
+ (UIImage *)takeScreenSnapshot;

// static method to take a snapshot of the application screen (with status bar)
// AND save to photos
+ (UIImage *)takeScreenSnapshotAndSave;

// static method to take a snapshot of the application screen with status bar...
+ (UIImage *)takeScreenSnapshotWithStatusBar;

// static method to take a snapshot of the application screen with no status bar...
+ (UIImage *)takeScreenSnapshotWithNoStatusBar;

// static method to take a snapshot of a view...
+ (UIImage *)takeScreenSnapshotOfView:(UIView *)view;

// constructor
- (id)initWithFrame:(CGRect)frame parent:(UIViewController *)parent;

// constructor
- (id)initWithFrame:(CGRect)frame parent:(UIViewController *)parent fullscreen:(BOOL)_fullScreen includeStatusBar:(BOOL)includeStatusBar;

- (void)includeAudio:(BOOL)includeAudio;

// for recording video...

- (BOOL)isRecording;        // determine if recording or not

- (BOOL)startRecording;     // start recording screen captures...
- (BOOL)startRecordingForTimePeriod:(int)seconds;  // start recording screen captures for so many seconds...

// for recording video for a specific view...
- (BOOL)startRecordingView:(UIView *)view parent:(UIViewController *)_parent;     // start recording screen captures for a view...
- (BOOL)startRecordingViewForTimePeriod:(int)seconds view:(UIView *)view parent:(UIViewController *)_parent;  // start recording screen captures for so many seconds for a view...

- (void)stopRecording;   // stop recording screen captures and save video...

// get the image for a view
- (UIImage *)screenCaptureView:(UIView *)view;

// get the screen capture image for a view rectangle
- (UIImage *)screenCaptureView2:(UIView *)view rect:(CGRect)rect;

// target is view to call the following method on with status...
// (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)
// on
- (void)saveToPhotos:(NSString *)outputName target:(UIViewController *)target;

// play video
- (void)playVideo:(NSURL *)videoUrl parent:(UIViewController *)parent;

// take a screenshot of the screen.  arg currently isn't used so can be nil
- (void)takeScreenshotSnapshotOnThreadTimer:(NSTimer *)timer;
- (void)takeScreenshotSnapshotOnThread:(NSString *)arg; // use older iOS6- screen snapshot on background thread
- (void)takeScreenshot:(NSString *)arg;           // use older iOS6- screen snapshot on foreground thread
- (void)takeScreenshotOnThread:(NSString *)arg;     // use new iOS7 screen snapshot API on background thread
- (void)takeScreenshotSnapshot:(NSString *)arg;   // use new iOS7 screen snapshot API

// take a screenshot of the screen using QuartzCore.  arg currently isn't used so can be nil
- (UIImage *)takeQuartzScreenshot;

// get the current screenshot image
- (UIImage *)getCurrentScreenshot;

// get the screenshot for a UIView
- (UIImage *)getScreenshotForView:(UIView *)view;

// get the image for a UIView
- (UIImage *)getImageForView:(UIView *)view usePresentationLayer:(BOOL)usePresentationLayer;

// remove local copy of video
- (BOOL)removeLocalCopyOfVideo:(NSURL *)localFile;

// turn verbose mode on/off, useful for debugging issues.
- (void)setVerbose:(BOOL)verbose;

- (void)recordingTimerElapsed:(NSDictionary * )info;
- (UIScreenCaptureView *)getRecordingView:(UIView *)_view parent:(UIViewController *)parent;
- (CGContextRef)createBitmapContextOfSize:(CGSize)size;
- (void)drawRect:(CGRect)rect;
- (NSURL*)tempFileURL;
- (BOOL)setUpWriter;
- (void)cleanupWriter;
- (void)completeRecordingSession;
- (void)writeVideoFrameAtTime:(CMTime)tim;

- (void)drawRectOld:(CGRect)rect;

@end