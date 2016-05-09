//
//  UIScreenCaptureView.m
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

#import "UIScreenCaptureView.h"

#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface UIScreenCaptureView(Private)
- (void)writeVideoFrameAtTime:(CMTime)time;
@end

@implementation UIScreenCaptureView

@synthesize currentScreen;
@synthesize frameRate;
@synthesize delegate;
@synthesize outputName;

+ (UIImage *)takeScreenSnapshot {
    UIImage * screenshot = nil;
    
    screenshot = [UIScreenCaptureView takeScreenSnapshotWithNoStatusBar];
    
    return screenshot;
}

+ (UIImage *)takeScreenSnapshotAndSave {
    UIImage * screenshot = nil;
    
    screenshot = [UIScreenCaptureView takeScreenSnapshotWithStatusBar];
    
    [OTScreenshotHelper saveImageToPhotos:screenshot];
    
    return screenshot;
}

+ (UIImage *)takeScreenSnapshotWithStatusBar {
    UIImage * screenshot = nil;
    
    screenshot = [OTScreenshotHelper screenshotWithStatusBar:TRUE];
    
    return screenshot;
}

+ (UIImage *)takeScreenSnapshotWithNoStatusBar {
    UIImage * screenshot = nil;
    
    screenshot = [OTScreenshotHelper screenshotWithStatusBar:FALSE];
    
    return screenshot;
}

+ (UIImage *)takeScreenSnapshotOfView:(UIView *)view {
    UIImage * screenshot = nil;
    
    screenshot = [OTScreenshotHelper screenshotOfView:view];
    
    return screenshot;
}

- (void)initialize {
    
    // Initialization code
    self.clearsContextBeforeDrawing = YES;
    self.currentScreen = nil;
    self.frameRate = 10.0f;      // 10 frames per seconds
    
    _recording = FALSE;
    _timedRecording = FALSE;
    _verbose = FALSE;
    _useOldSnapshot = FALSE;            // if true, uses old snapshot even on iOS7
    _runSnapshotInBackground = TRUE;    // if true, run snapshot on background thread
    _snapshotThreadRunning = FALSE;
    _fullScreenWithNoStatusBar = FALSE; // default is not fullscreen, just view
    _fullScreenWithStatusBar = FALSE;   // default is not fullscreen, just view
    _includeAudio = FALSE;              // default is to not include audio
    _parent = nil;
    _viewParent = nil;
    videoWriter = nil;
    videoWriterInput = nil;
    avAdaptor = nil;
    startedAt = nil;
    bitmapData = nil;
    
    savedView = nil;
    savedViewParent = nil;
    recordingView = nil;
    
    outputName = @"video.mp4";   // file for output video
    self.layer.contentsScale = [[UIScreen mainScreen] scale];
}

- (void)setVerbose:(BOOL)verbose {
    
    _verbose = verbose;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        [self initialize];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame parent:(UIViewController *)parent {
    self = [super initWithFrame:frame];
    if (self) {
        _parent = parent;
        self.backgroundColor = [UIColor blackColor];
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame parent:(UIViewController *)parent fullscreen:(BOOL)_fullScreen includeStatusBar:(BOOL)includeStatusBar {
    
    self = [super initWithFrame:frame];
    if (self) {
        _parent = parent;
        self.backgroundColor = [UIColor blackColor];
        [self initialize];
        
        if (_fullScreen && includeStatusBar) {
            _fullScreenWithStatusBar = TRUE;
            _fullScreenWithNoStatusBar = FALSE;
            
        } else if (_fullScreen && !includeStatusBar) {
            _fullScreenWithNoStatusBar = TRUE;
            _fullScreenWithStatusBar = FALSE;
            
        } else {
            _fullScreenWithNoStatusBar = FALSE;
            _fullScreenWithStatusBar = FALSE;
        }
        
    }
    return self;
}

// whether to include audio or not
//
// if audio is included the video file is a .mov QuickTime Movie file
// if audio if not included, the video file is an .mp4 file
- (void)includeAudio:(BOOL)includeAudio {
    
    _includeAudio = includeAudio;
}

- (BOOL)isRecording {
    
    return _recording;
}

// start recording of the screen capture video...
- (BOOL)startRecording {
    BOOL result = NO;
    
    @synchronized(self) {
        if (! _recording) {
            result = [self setUpWriter];
            startedAt = [NSDate date];
            _recording = TRUE;
            _viewParent = nil;
            [self setNeedsDisplay];
        }
    }
    
    return result;
}

// start recording for N seconds...
- (BOOL)startRecordingForTimePeriod:(int)seconds {
    BOOL result = FALSE;
    
    @try {
        timerTotalSeconds = seconds;
        timerElapsedSeconds = 0;
        _timedRecording = TRUE;
        _viewParent = nil;
        
        result = [self startRecording];
        
        // timer ever second
        recordingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(recordingTimerElapsed:) userInfo:nil repeats:YES];
    }
    @catch (NSException * ex) {
        NSLog(@"[startRecordingForTimePeriod]  error: %@", [ex description]);
    }
    
    return result;
}

// start recording of the screen capture video for a view...
- (BOOL)startRecordingView:(UIView *)view parent:(UIViewController *)parent {
    BOOL result = NO;
    
    @try {
        _viewParent = nil;
        _checkRunning = TRUE;
        
        // save view, original parent and view location
        savedView = view;
        savedViewParent = view.superview;
        if (savedViewParent == parent.view) {
            NSLog(@"view.supeview == parent");
        } else {
            NSLog(@"view.superview != parent");
        }
        savedViewFrame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, view.frame.size.height);
        
        recordingView = [self getRecordingView:view parent:parent];
        [savedViewParent addSubview:recordingView];
        
        result = [recordingView startRecording];
    }
    @catch (NSException * ex) {
        NSLog(@"[startRecordingView]  error: %@", [ex description]);
    }
    
    return result;
}

// start recording for N seconds for a view...
- (BOOL)startRecordingViewForTimePeriod:(int)seconds view:(UIView *)view parent:(UIViewController *)parent {
    BOOL result = FALSE;
    
    @try {
        _parent = parent;
        _viewParent = nil;
        
        // save view, original parent and view location
        savedView = view;
        savedViewParent = view.superview;
        savedViewFrame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, view.frame.size.height);
        
        recordingView = [self getRecordingView:view parent:_parent];
        [savedViewParent addSubview:recordingView];
        
        timerTotalSeconds = seconds;
        timerElapsedSeconds = 0;
        _timedRecording = TRUE;
        _checkRunning = TRUE;
        
        result = [recordingView startRecordingForTimePeriod:seconds];
    }
    @catch (NSException * ex) {
        NSLog(@"[startRecordingViewForTimePeriod] error: %@", [ex description]);
    }
    
    return result;
}

- (UIScreenCaptureView *)getRecordingView:(UIView *)_view parent:(UIViewController *)parent {
    UIScreenCaptureView * _recordingView = nil;
    
    @try {
        _recordingView = [[UIScreenCaptureView alloc] initWithFrame:_view.frame parent:parent];
        _recordingView.backgroundColor = [UIColor clearColor];
        //_recordingView.layer.borderWidth = 1;
        //_recordingView.layer.borderColor = [UIColor yellowColor].CGColor;
        _recordingView.delegate = self;
        
        // set view x/y relative to new parent...
        _view.frame = CGRectMake(0, 0, _view.frame.size.width, _view.frame.size.height);
        
        [_recordingView addSubview:_view];
    }
    @catch (NSException * ex) {
        NSLog(@"[getRecordingView] error: %@", [ex description]);
    }
    
    return _recordingView;
}

- (void)recordingFinished:(NSURL *)outputPathOrNil {
    
    if (_parent != nil &&
        [_parent respondsToSelector:@selector(recordingFinished:)]) {
        [_parent performSelectorOnMainThread:@selector(recordingFinished:) withObject:outputPathOrNil  waitUntilDone:YES];
    }
}

- (void)recordingTimerElapsed:(NSDictionary * )info {
    
    timerElapsedSeconds++;
    
    if (_verbose)
        NSLog(@"%d of %d seconds has elapsed...", timerElapsedSeconds, timerTotalSeconds);
    
    if (timerElapsedSeconds >= timerTotalSeconds) {
        [recordingTimer invalidate];
        _timedRecording = FALSE;
        
        if (_verbose)
            NSLog(@"Time of %d seconds has expired so stopping recording...", timerTotalSeconds);
        
        [self stopRecording];
    }
}

// stop recording of the screen capture video...
- (void)stopRecording {
    
    @try {
        if (recordingView != nil) {
            NSLog(@"stop recording on special view...");
            
            [recordingView stopRecording];
            [recordingView removeFromSuperview];
            savedView.frame = savedViewFrame;
            [savedViewParent addSubview:savedView];
            _checkRunning = FALSE;
            savedView = nil;
            savedViewParent = nil;
            recordingView = nil;
        } else {
            
            @synchronized(self) {
                if (_recording) {
                    
                    if (_verbose)
                        NSLog(@"stop recording...");
                    _recording = FALSE;
                    
                    [self completeRecordingSession];
                }
            }
        }
    }
    @catch (NSException * ex) {
        NSLog(@"[stopRecording] error: %@", [ex description]);
    }
    
}

// get the screen capture image for a view
- (UIImage*)screenCaptureView:(UIView *)view {
    UIImage * image = nil;
    
    @try {
        UIGraphicsBeginImageContext(view.frame.size);
        //[view.layer renderInContext:UIGraphicsGetCurrentContext()];
        [[view.layer presentationLayer] renderInContext:UIGraphicsGetCurrentContext()];
        
        UIImage * captureImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (captureImage != nil)
            image = captureImage;
    }
    @catch (NSException * ex) {
        NSLog(@"[screenCaptureView]  error: %@", [ex description]);
    }
    
    return image;
}

// get the screen capture image for a view
- (UIImage*)screenCaptureView2:(UIView *)view rect:(CGRect)rect {
    UIImage * image = nil;
    
    @try {
        UIGraphicsBeginImageContext(view.frame.size);
        //[view.layer renderInContext:UIGraphicsGetCurrentContext()];
        [[view.layer presentationLayer] renderInContext:UIGraphicsGetCurrentContext()];
        UIImage * captureImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        CGImageRef imageRef = CGImageCreateWithImageInRect([captureImage CGImage], rect);
        UIImage * subImage = [UIImage imageWithCGImage: imageRef];
        CGImageRelease(imageRef);
        
        if (subImage != nil)
            image = subImage;
    }
    @catch (NSException * ex) {
        NSLog(@"[screenCaptureView2]  error: %@", [ex description]);
    }
    
    return image;
}

// save video to Photos
- (void)saveToPhotos:(NSString *)_outputName target:(UIView *)target {
    
    id delegateObj = self.delegate;
    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init]; [library writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:_outputName] completionBlock:^(NSURL *assetURL, NSError *error) {
        
        if ([delegateObj respondsToSelector:@selector(assetURL:error:)]) {
            [delegateObj assetURL:assetURL error:error];
        }
    }];
    
    // old
    //UISaveVideoAtPathToSavedPhotosAlbum(_outputName, target, @selector(video:didFinishSavingWithError:contextInfo:), nil);
}

// play video
- (void)playVideo:(NSURL *)_videoUrl parent:(UIViewController *)parent {
    
    myVideoPlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:_videoUrl];
    MPMoviePlayerController * videoPlayer = myVideoPlayer.moviePlayer;
    [videoPlayer setAllowsAirPlay:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myMovieFinishedCallback:) name:MPMoviePlayerPlaybackDidFinishNotification object:videoPlayer];
    
    videoPlayer.controlStyle = MPMovieControlStyleFullscreen;
    videoPlayer.initialPlaybackTime = 0;
    videoPlayer.fullscreen = TRUE;
    videoPlayer.shouldAutoplay = FALSE;
    
    [parent presentMoviePlayerViewControllerAnimated:myVideoPlayer];
}

- (void)myMovieFinishedCallback:(NSNotification *)aNotification {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:myVideoPlayer.moviePlayer];
}

// remove the local copy of the recorded video
- (BOOL)removeLocalCopyOfVideo:(NSURL *)localFile {
    BOOL result = FALSE;
    
    @try {
        NSFileManager * fileManager = [NSFileManager defaultManager];
        
        if (_verbose )
            NSLog(@"Removing the local recording file at path:  %@", localFile);
        
        NSError * error = nil;
        
        if ([fileManager fileExistsAtPath:[localFile path]] == NO) {
            if (_verbose)
                NSLog(@"the file %@ does not exist!", [localFile path]);
            
        } else if ([fileManager removeItemAtURL:localFile error:&error] == NO) {
            if (_verbose)
                NSLog(@"Error removing the local recording file at path:  %@ error: %@!", localFile, [error description]);
        } else {
            if (_verbose)
                NSLog(@"Removed the local recording file at path:  %@", localFile);
            result = TRUE;
        }
    }
    @catch (NSException * ex) {
        //NSLog(@"[removeLocalCopyOfVideo] error: %@", [ex description]);
    }
    
    return result;
}

- (CGContextRef)createBitmapContextOfSize:(CGSize)size {
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    int bitmapByteCount;
    int bitmapBytesPerRow;
    
    bitmapBytesPerRow   = (size.width * 4);
    bitmapByteCount     = (bitmapBytesPerRow * size.height);
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (bitmapData != nil) {
        free(bitmapData);
    }
    
    bitmapData = malloc(bitmapByteCount);
    
    if (bitmapData == nil) {
        fprintf (stderr, "Memory could not be allocated!");
        
        return NULL;
    }
    
    context = CGBitmapContextCreate (bitmapData,
                                     size.width,
                                     size.height,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaNoneSkipFirst);
    
    CGContextSetAllowsAntialiasing(context, NO);
    
    if (context== NULL) {
        free (bitmapData);
        fprintf (stderr, "Context was not created!");
        return NULL;
    }
    
    CGColorSpaceRelease(colorSpace);
    
    return context;
}

- (void)drawRect:(CGRect)rect {
    
    if (_recording) {
        if (!_useOldSnapshot && [self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
            
            if (_runSnapshotInBackground && !_snapshotThreadRunning) {
                //NSLog(@"iOS7+ screen snapshot on background thread...");
                
                _snapshotThreadRunning = TRUE;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    [self takeScreenshotSnapshot:nil];
                });
                // [NSThread detachNewThreadSelector:@selector(takeScreenshotSnapshotOnThread:) toTarget:self withObject:nil];
            } else {
                //NSLog(@"iOS7+ screen snapshot on foreground thread...");
                
                [self performSelectorOnMainThread:@selector(takeScreenshotSnapshot:) withObject:nil waitUntilDone:FALSE];
            }
            
        } else {
            
            if (_runSnapshotInBackground && !_snapshotThreadRunning) {
                //NSLog(@"iOS6- screenshot on background thread...");
                
                _snapshotThreadRunning = TRUE;
                [NSThread detachNewThreadSelector:@selector(takeScreenshotOnThread:) toTarget:self withObject:nil];
            } else {
                //NSLog(@"iOS6- screenshot on foreground thread...");
                
                [self performSelectorOnMainThread:@selector(takeScreenshot:) withObject:nil waitUntilDone:FALSE];
            }
        }
    }
}

// iOS7

// timer for taking iOS7+ screen snapshot on a background thread
- (void)takeScreenshotSnapshotOnThreadTimer:(NSTimer *)timer {
    
    // This should avoid random crash
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self takeScreenshotSnapshot:nil];
    });
    
    // Old code
    //[NSThread detachNewThreadSelector:@selector(takeScreenshotSnapshotOnThread:) toTarget:self withObject:nil];
}

// thread to take iOS7+ screen snapshot on a background thread...
- (void)takeScreenshotSnapshotOnThread:(NSString *)arg {
    
    @autoreleasepool {
        [self takeScreenshotSnapshot:nil];
    }
}

- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(NSDictionary *)info {
    
}

// take iOS7+ screen snapshot...
- (void)takeScreenshotSnapshot:(NSString *)arg {
    
    //NSLog(@"on thread using new iOS7 screen snapshot...");
    
    NSDate * start = [NSDate date];
    float _scale = [[UIScreen mainScreen] scale];
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, _scale);
    //NSLog(@"scale is %f bounds width %f height %f", _scale, self.bounds.size.width, self.bounds.size.height);
    
    UIGraphicsEndImageContext();
    UIImage * screenshot = nil;
    
    // not fullscreen, so view only
    if (!_fullScreenWithStatusBar && !_fullScreenWithNoStatusBar) {
        if (_verbose)
            NSLog(@"getScreenshotForView...");
        screenshot = [self getScreenshotForView:self];
        
        // fullscreen and status bar
    } else if (_fullScreenWithStatusBar) {
        if (_verbose)
            NSLog(@"takeScreenSnapshotWithStatusBar...");
        screenshot = [UIScreenCaptureView takeScreenSnapshotWithStatusBar];
        
        // fullscreen with no status bar
    } else if (_fullScreenWithNoStatusBar) {
        if (_verbose)
            NSLog(@"takeScreenSnapshotWithNoStatusBar...");
        screenshot = [UIScreenCaptureView takeScreenSnapshotWithNoStatusBar];
    }
    
    self.currentScreen = screenshot;
    
    if (_recording) {
        float millisElapsed = [[NSDate date] timeIntervalSinceDate:startedAt] * 1000.0;
        [self writeVideoFrameAtTime:CMTimeMake((int)millisElapsed, 1000)];
    }
    
    float processingSeconds = [[NSDate date] timeIntervalSinceDate:start];
    float delayRemaining = (1.0 / self.frameRate) - processingSeconds;
    
    if (_verbose)
        NSLog(@"time elapsed was %f seconds & %f seconds are remaining...", processingSeconds, delayRemaining);
    
    [NSThread sleepForTimeInterval:delayRemaining > 0.0 ? delayRemaining : 0.01];
    //NSLog(@"--> exiting on thread using new iOS7 screen snapshot...");
    _snapshotThreadRunning = FALSE;
    
    // redraw at the specified framerate
    [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:FALSE];
    //[self performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:delayRemaining > 0.0 ? delayRemaining : 0.01];
}

// iOS6-

// timer for taking iOS6- screen snapshot on a background thread
- (void)takeScreenshotOnThreadTimer:(NSTimer *)timer {
    
    [NSThread detachNewThreadSelector:@selector(takeScreenshotOnThread:) toTarget:self withObject:nil];
}

// thread to take iOS6- screen snapshot on a background thread...
- (void)takeScreenshotOnThread:(NSString *)arg {
    
    @autoreleasepool {
        [self takeScreenshot:nil];
    }
}

// take iOS6- screen snapshot...
- (void)takeScreenshot:(NSString *)arg {
    
    //NSLog(@"on thread using old iOS6- screen snapshot...");
    
    NSDate * start = [NSDate date];
    CGFloat scale = [[UIScreen mainScreen] scale];
    scale = 1.0;
    CGSize scaledSize = CGSizeMake(self.bounds.size.width*scale, self.bounds.size.height*scale);
    CGContextRef context = [self createBitmapContextOfSize:scaledSize];
    
    // need to do because image renders upside-down and mirrored
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, self.bounds.size.height*scale);
    CGContextConcatCTM(context, flipVertical);
    
    if (scale > 1.0)
        CGContextScaleCTM(context, scale, scale);
    
    //NSLog(@"scale is %f", scale);
    [[self.layer presentationLayer] renderInContext:context];
    
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    CGFloat _scale = [[UIScreen mainScreen] scale];
    NSLog(@"_scale is %f", _scale);
    _scale = 1;
    UIImage* background = [UIImage imageWithCGImage:cgImage scale:_scale orientation:UIImageOrientationDownMirrored];
    CGImageRelease(cgImage);
    
    self.currentScreen = background;
    
    // NOTE: to record a scrollview while it is scrolling you need to
    // implement your UIScrollViewDelegate such that it calls 'setNeedsDisplay'
    // on the UIScreenCaptureView.
    //
    if (_recording) {
        float millisElapsed = [[NSDate date] timeIntervalSinceDate:startedAt] * 1000.0;
        [self writeVideoFrameAtTime:CMTimeMake((int)millisElapsed, 1000)];
    }
    
    float processingSeconds = [[NSDate date] timeIntervalSinceDate:start];
    float delayRemaining = (1.0 / self.frameRate) - processingSeconds;
    
    CGContextRelease(context);
    
    //if (_verbose)
    NSLog(@"2time elapsed was %f seconds & %f seconds are remaining...", processingSeconds, delayRemaining);
    
    [NSThread sleepForTimeInterval:delayRemaining > 0.0 ? delayRemaining : 0.01];
    //NSLog(@"--> exiting on thread using new iOS6- screen snapshot...");
    _snapshotThreadRunning = FALSE;
    
    // redraw at the specified framerate
    [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:FALSE];
    //[self performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:delayRemaining > 0.0 ? delayRemaining : 0.01];
}

// take a screenshot using QuartzCore...
- (UIImage *)takeQuartzScreenshot {
    
    // Create a graphics context with the target size
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
    //
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    
    if (NULL != UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    else
        UIGraphicsBeginImageContext(imageSize);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Iterate over every window from back to front
    for (UIWindow * window in [[UIApplication sharedApplication] windows])
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context
            CGContextSaveGState(context);
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
            
            // Render the layer hierarchy to the current context
            //[[window layer] renderInContext:context];
            [[[window layer] presentationLayer] renderInContext:context];
            
            // Restore the context
            CGContextRestoreGState(context);
        }
    }
    
    // Retrieve the screenshot image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

// get the current screenshot image
- (UIImage *)getCurrentScreenshot {
    
    return self.currentScreen;
}

- (void)cleanupWriter {
    avAdaptor = nil;
    
    videoWriterInput = nil;
    
    videoWriter = nil;
    
    startedAt = nil;
    
    if (bitmapData != NULL) {
        free(bitmapData);
        bitmapData = NULL;
    }
}

- (NSURL*)tempFileURL {
    NSString * outputPath = [[NSString alloc] initWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], outputName];
    NSURL * outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    if (_verbose)
        NSLog(@"tempPath is '%@", outputPath);
    
    if ([fileManager fileExistsAtPath:outputPath]) {
        NSError * error;
        
        if ([fileManager removeItemAtPath:outputPath error:&error] == NO) {
            if (_verbose)
                NSLog(@"Could not delete old recording file at path:  %@", outputPath);
        }
    }
    
    
    return outputURL;
}

- (BOOL)setUpWriter {
    
    if (_verbose)
        NSLog(@"setup Writer...");
    
    NSError * error = nil;
    videoWriter = [[AVAssetWriter alloc] initWithURL:[self tempFileURL] fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    
    videoOutPath = [[NSString alloc] initWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], outputName];
    
    // Configure video
    NSDictionary * videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithDouble:1024.0*1024.0], AVVideoAverageBitRateKey,
                                            nil ];
    
    NSDictionary * videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    AVVideoCodecH264, AVVideoCodecKey,
                                    [NSNumber numberWithInt:self.bounds.size.width], AVVideoWidthKey,
                                    [NSNumber numberWithInt:self.bounds.size.height], AVVideoHeightKey,
                                    videoCompressionProps, AVVideoCompressionPropertiesKey,
                                    nil];
    
    videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    if (_includeAudio) {
        NSLog(@"include audio..");
    } else {
        NSLog(@"do not include audio..");
    }
    
    // record audio, if requested...
    if (_includeAudio) {
        if (_verbose)
            NSLog(@"including audio with recording...");
        
        // Setup to be able to record global sounds (preexisting app sounds)
        NSError * sessionError = nil;
        
        if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(setCategory:withOptions:error:)])
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDuckOthers error:&sessionError];
        else
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        
        NSError *setOverrideError;
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&setOverrideError];

        NSArray * inputs = [[AVAudioSession sharedInstance] availableInputs];
        NSLog(@"audio inputs %@", inputs);
        
        // Set the audio session to be active
        [[AVAudioSession sharedInstance] setActive:YES error:&sessionError];
        
        // Set the number of audio channels, using defaults if necessary.
        NSNumber * audioQuality = [NSNumber numberWithInt:AVAudioQualityMin];
        NSNumber * audioChannels = @2;
        NSNumber * sampleRate = @44100.f;
        
        NSDictionary * audioSettings = @{
                                         AVEncoderAudioQualityKey : (audioQuality ? audioQuality : audioQuality),
                                         AVNumberOfChannelsKey : (audioChannels ? audioChannels : @2),
                                         AVSampleRateKey : (sampleRate ? sampleRate : @44100.0f)
                                         };
        
        // Initialize the audio recorder
        // Set output path of the audio file
        NSError * error = nil;
        
        audioOutPath = [[self inDocumentsDirectory:@"audio.caf"] copy];
        audioRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:audioOutPath] settings:audioSettings error:&error];
        
        if (error) {
            audioRecorder = nil;
            
            return NO;
        }
        
        //[audioRecorder setDelegate:self];
        [audioRecorder prepareToRecord];
        
        // Start recording :P
        [audioRecorder record];
        
    } else {
        NSLog(@"not including audio with recording...");
    }
    
    NSParameterAssert(videoWriterInput);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    NSDictionary * bufferAttributes = nil;
    
    if (!_useOldSnapshot && [self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
        
    } else {
        bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    }
    
    avAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:bufferAttributes];
    
    //add input
    [videoWriter addInput:videoWriterInput];
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];
    
    return YES;
}

- (NSString *)inDocumentsDirectory:(NSString *)path {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    return [documentsDirectory stringByAppendingPathComponent:path];
}

- (NSString *)addAudioTrackToRecording {
    NSString * exportPath = nil;
    double degrees = 0.0;
    NSString * videoPath = videoOutPath;
    NSString * audioPath = audioOutPath;
    
    if (_verbose) {
        NSLog(@"video out path is '%@'", videoPath);
        NSLog(@"audio out path is '%@'", audioPath);
    }
    
    NSURL * videoURL = [NSURL fileURLWithPath:videoPath];
    NSURL * audioURL = [NSURL fileURLWithPath:audioPath];
    
    AVURLAsset * videoAsset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    AVURLAsset * audioAsset = [[AVURLAsset alloc] initWithURL:audioURL options:nil];
    
    AVAssetTrack * assetVideoTrack = nil;
    AVAssetTrack * assetAudioTrack = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
        if (_verbose)
            NSLog(@"video file exists...");
        
        NSArray *assetArray = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
        
        if ([assetArray count] > 0) {
            assetVideoTrack = assetArray[0];
            
            if (_verbose)
                NSLog(@"have video asset...");
        }
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:audioPath]) {
        if (_verbose)
            NSLog(@"audio file exists...");
        
        NSArray *assetArray = [audioAsset tracksWithMediaType:AVMediaTypeAudio];
        
        if ([assetArray count] > 0) {
            assetAudioTrack = assetArray[0];
            
            if (_verbose)
                NSLog(@"have audio asset...");
        }
    }
    
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    
    if (assetVideoTrack != nil) {
        AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:assetVideoTrack atTime:kCMTimeZero error:nil];
        
        if (assetAudioTrack != nil) [compositionVideoTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) toDuration:audioAsset.duration];
        
        [compositionVideoTrack setPreferredTransform:CGAffineTransformMakeRotation(degrees)];
    }
    
    if (assetAudioTrack != nil) {
        AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:assetAudioTrack atTime:kCMTimeZero error:nil];
    }
    
    exportPath = [videoPath substringWithRange:NSMakeRange(0, videoPath.length - 4)];
    exportPath = [NSString stringWithFormat:@"%@_with_audio.mov", [exportPath copy]];
    NSURL * exportURL = [NSURL fileURLWithPath:exportPath];
    
    //NSLog(@"export path is %@", exportPath);
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:exportPath]) {
        //NSLog(@"the export path %@ does exist!", exportPath);
        
        NSError * error;
        if ([fileManager removeItemAtURL:exportURL error:&error] == YES) {
            //NSLog(@"--> removed file successfully...");
        } else {
            //NSLog(@"--> did not remove the file!");
        }
    }
    
    AVAssetExportSession * exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetPassthrough];
    [exportSession setOutputFileType:AVFileTypeQuickTimeMovie];
    //[exportSession setOutputFileType:AVFileTypeMPEG4];
    [exportSession setOutputURL:exportURL];
    [exportSession setShouldOptimizeForNetworkUse:NO];
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        
        switch (exportSession.status) {
                
            case AVAssetExportSessionStatusCompleted: {
                
                [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
                [[NSFileManager defaultManager] removeItemAtPath:audioPath error:nil];
                
                break;
            }
                
            case AVAssetExportSessionStatusFailed:
                
                videoAsset;
                
                if (_verbose)
                    NSLog(@"Failed: %@", exportSession.error);
                
                break;
                
            case AVAssetExportSessionStatusCancelled:
                
                videoAsset;
                
                if (_verbose)
                    NSLog(@"Canceled: %@", exportSession.error);
                
                break;
                
            default:
                
                videoAsset;
                break;
        }
    }];
    
    return exportPath;
}

- (void)completeRecordingSession {
    @autoreleasepool {
        
        if (_verbose)
            NSLog(@"completing recording...");
        
        [videoWriterInput markAsFinished];
        
        if (_includeAudio) {
            
            // Stop the audio recording
            [audioRecorder stop];
            audioRecorder = nil;
        }
        
        // Wait for the video
        int status = videoWriter.status;
        while (status == AVAssetWriterStatusUnknown) {
            if (_verbose)
                NSLog(@"Waiting...");
            [NSThread sleepForTimeInterval:0.5f];
            status = videoWriter.status;
        }
        
        @synchronized(self) {
            _completed = FALSE;
            _success = FALSE;
            
            // see if iOS6+; use newer AVAssetWriter method
            if ([videoWriter respondsToSelector:@selector(finishWritingWithCompletionHandler:)]) {
                
                if (_verbose)
                    NSLog(@"runing iOS6 so use new AVAssetWriter completion handler...");
                
                [videoWriter finishWritingWithCompletionHandler:^(){
                    
                    if (_verbose)
                        NSLog(@"finished writing...");
                    
                    AVAssetWriterStatus status = videoWriter.status;
                    _success = FALSE;
                    
                    if (status == AVAssetWriterStatusCompleted)
                        _success = TRUE;
                    
                    if (!_success) {
                        if (_verbose)
                            NSLog(@"finishWriting returned NO");
                    }
                    
                    _completed = TRUE;
                }];
                
                // < iOS6; use older AVAssetWriter method
            } else {
                
                if (_verbose)
                    NSLog(@"using before iOS6 so use old AVAssetWriter method...");
                
                _success = [videoWriter finishWriting];
                
                if (!_success) {
                    if (_verbose)
                        NSLog(@"finishWriting returned NO");
                }
                
                _completed = TRUE;
            }
            
            while (!_completed) {
                [NSThread sleepForTimeInterval:1];
                if (_verbose)
                    NSLog(@"waiting for completion...");
            }
            
            if (_verbose) {
                if (_success)
                    NSLog(@"completed OK");
                else
                    NSLog(@"completed with error!");
            }
            
            [self cleanupWriter];
            
            id delegateObj = self.delegate;
            NSString *outputPath = [[NSString alloc] initWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], outputName];
            NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
            
            if (_verbose)
                NSLog(@"Completed recording, file is stored at:  %@", outputURL);
            
            
            if (_includeAudio) {
                
                // add recorded audio to the video...
                NSString * exportPath = [self addAudioTrackToRecording];
                
                // set outputURL to path o video with audio merged in...
                NSURL * exportURL = [NSURL fileURLWithPath:exportPath];
                
                outputURL = [exportURL copy];
                
                if (_verbose)
                    NSLog(@"output URL with audio merged is %@", exportPath);
                
            } else {
                if (_verbose)
                    NSLog(@"output URL with NO audio merged is %@", outputPath);
            }
            
            
            // Setup to be able to record global sounds (preexisting app sounds)
            NSError * sessionError = nil;
            
            // set back to playback
            if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(setCategory:withOptions:error:)])
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:&sessionError];
            else
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&sessionError];

            if ([delegateObj respondsToSelector:@selector(recordingFinished:)]) {
                [delegateObj performSelectorOnMainThread:@selector(recordingFinished:) withObject:(_success ? outputURL : nil) waitUntilDone:YES];
            }
            
        }
        
    }
}

- (void)writeVideoFrameAtTime:(CMTime)time {
    
    if (![videoWriterInput isReadyForMoreMediaData]) {
        if (_verbose)
            NSLog(@"Not ready for video data");
    } else {
        @synchronized (self) {
            
            //NSLog(@"current screen is %@  (%f X %f)", self.currentScreen, self.currentScreen.size.width, self.currentScreen.size.height);
            UIImage* newFrame = self.currentScreen;
            CVPixelBufferRef pixelBuffer = NULL;
            CGImageRef cgImage = CGImageCreateCopy([newFrame CGImage]);
            CFDataRef image = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
            NSDictionary * options = nil;
            
            if (!_useOldSnapshot && [self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
                if (_verbose)
                    NSLog(@"using 32BGRA for attributes...");
                options = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
                // options = [NSDictionary dictionaryWithObjectsAndKeys:
                //            [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                //            [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                //            [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
            } else {
                if (_verbose)
                    NSLog(@"using 32ARGB for attributes...");
                options = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
                //options = [NSDictionary dictionaryWithObjectsAndKeys:
                //           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey,
                //           [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                //           [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
            }
            
            CFDictionaryRef dictionaryRef = CFBridgingRetain(options);
            CVReturn status;
            
            if (!_useOldSnapshot && [self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
                if (_verbose)
                    NSLog(@"using 32BGRA for create...");
                int _scale = [UIScreen mainScreen].scale;
                if (_verbose)
                    NSLog(@"scale is %d", _scale);
                status = CVPixelBufferCreate(kCFAllocatorDefault, newFrame.size.width*_scale, newFrame.size.height*_scale, kCVPixelFormatType_32BGRA, dictionaryRef, &pixelBuffer);
            } else {
                if (_verbose)
                    NSLog(@"using 32ARGB for create...");
                status = CVPixelBufferCreate(kCFAllocatorDefault, newFrame.size.width, newFrame.size.height, kCVPixelFormatType_32ARGB, dictionaryRef, &pixelBuffer);
            }
            
            //int status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, avAdaptor.pixelBufferPool, &pixelBuffer);
            //xx CVReturn status = CVPixelBufferPoolCreatePixelBuffer(NULL, avAdaptor.pixelBufferPool, &pixelBuffer);
            
            if(status != 0){
                //could not get a buffer from the pool
                if (_verbose)
                    NSLog(@"Error creating pixel buffer:  status=%d", status);
            }
            
            if (_verbose) {
                size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
                NSLog(@"bytes per row %lu", bytesPerRow);
            }
            
            // set image data into pixel buffer
            CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
            uint8_t* destPixels = CVPixelBufferGetBaseAddress(pixelBuffer);
            
            //NSLog(@"image length is %ld (width %f height %f)", CFDataGetLength(image), newFrame.size.width, newFrame.size.height);
            
            CFDataGetBytes(image, CFRangeMake(0, CFDataGetLength(image)), destPixels);  // Note:  will work if the pixel buffer is contiguous and has the same bytesPerRow as the input data
            
            if(status == 0){
                BOOL success = [avAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];
                if (!success) {
                    if (_verbose)
                        NSLog(@"Warning:  Unable to write buffer to video");
                }
            }
            
            //clean up
            CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
            CVPixelBufferRelease( pixelBuffer );
            CFRelease(image);
            CGImageRelease(cgImage);
        }
        
    }
    
}

// get the screenshot for a UIView
- (UIImage *)getScreenshotForView:(UIView *)view {
    UIImage * screenshot = nil;
    
    @try {
        screenshot = [OTScreenshotHelper screenshotOfView:view];
    }
    @catch (NSException * ex) {
        NSLog(@"[getScreenshotForView] error %@", [ex description]);
    }
    
    return screenshot;
}

// get the image for a UIView
- (UIImage *)getImageForView:(UIView *)view usePresentationLayer:(BOOL)usePresentationLayer {
    UIImage * image = nil;
    
    @try {
        UIGraphicsBeginImageContext(view.bounds.size);
        
        if (usePresentationLayer)
            [[view.layer presentationLayer] renderInContext:UIGraphicsGetCurrentContext()];
        else
            [view.layer renderInContext:UIGraphicsGetCurrentContext()];
        
        UIImage * mapImage = UIGraphicsGetImageFromCurrentImageContext();
        NSData * data = UIImagePNGRepresentation(mapImage);
        
        //image = [[[UIImage alloc] initWithData:data] retain];
        image = [[UIImage alloc] initWithData:data];
    }
    @catch (NSException * ex) {
        NSLog(@"[getImageForView] error %@", [ex description]);
    }
    
    return image;
}

// old draw rect
- (void)drawRectOld:(CGRect)rect {
    NSDate * start = [NSDate date];
    CGContextRef context = [self createBitmapContextOfSize:self.bounds.size];
    
    //not sure why this is necessary...image renders upside-down and mirrored
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, self.bounds.size.height);
    CGContextConcatCTM(context, flipVertical);
    
    //[self.layer renderInContext:context];
    [[self.layer presentationLayer] renderInContext:context];
    
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage* background = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    self.currentScreen = background;
    
    // NOTE:  to record a scrollview while it is scrolling you need to implement your UIScrollViewDelegate such that it calls
    //       'setNeedsDisplay' on the UIScreenCaptureView.
    if (_recording) {
        float millisElapsed = [[NSDate date] timeIntervalSinceDate:startedAt] * 1000.0;
        [self writeVideoFrameAtTime:CMTimeMake((int)millisElapsed, 1000)];
    }
    
    float processingSeconds = [[NSDate date] timeIntervalSinceDate:start];
    float delayRemaining = (1.0 / self.frameRate) - processingSeconds;
    
    CGContextRelease(context);
    
    //redraw at the specified framerate
    
    //NSLog(@"repaint after %f", delayRemaining);
    
    [self performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:delayRemaining > 0.0 ? delayRemaining : 0.01];
}

- (void)dealloc {
    [self cleanupWriter];
}    

@end