//
//  AVPlayerView.m
//  AddMusic
//
//  Created by li taixu on 2/22/13.
//
//

#import "AVPlayerView.h"
#import <CoreMedia/CoreMedia.h>
#import <AudioToolbox/AudioServices.h>
#import <CoreImage/CoreImage.h>

#define SELF_DRAW 1

@implementation AVPlayerView
{
    float               _frameRate;
    float               _avgFrameDuration;
    CMTime              _cmTimeDelta;
    
    float               _rate;
    BOOL                _bManualSeek;
    NSTimer *           _manualSeekTimer;
    
    float               _durationF;
    CMTime              _durationCM;
    
    AVPlayerItemVideoOutput *    _playerItemVideoOutput;
    NSTimer *           _refreshTimer;
    
    
    CGAffineTransform   _txf;
    CGSize              _naturalSize;
    int              _visibleVideoWidth;
    int              _visibleVideoHeight;
    BOOL                _isRotated;
}

@synthesize player;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
    }
    
    return self;
}

- (void)initPlayer
{
    self.player = nil;
    m_playerLayer = nil;
    m_isStoped = YES;
    m_isLoop = NO;
    
    _bManualSeek = NO;
}

- (void)dealloc
{
    [self uninitPlayer];
}

- (void)uninitPlayer
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self stop];
    [self.player.currentItem removeOutput:_playerItemVideoOutput];
    self.player = nil;
    
    [_refreshTimer invalidate];
    _refreshTimer = nil;
    
    if (m_playerLayer)
    {
        [m_playerLayer removeFromSuperlayer];
        m_playerLayer = nil;
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    if (m_playerLayer)
        m_playerLayer.frame = self.bounds;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    if (m_playerLayer)
        m_playerLayer.frame = self.bounds;
}

#pragma mark - Notification
- (void)playerDidReachedEnd:(id)sender
{   
    [self.player pause];
    [self.player seekToTime:kCMTimeZero];
    if (m_isLoop)
    {
        [self.player setRate:_rate];
        [self.player play];
    } else {
        m_isStoped = YES;
    }
}

#pragma mark - Playback Control
- (void)setFilePath:(NSString *)filePath isAudio:(BOOL)isAudio
{
    [self setFileURL:[NSURL fileURLWithPath:filePath] isAudio:isAudio];
}

- (void)setFileURL:(NSURL *)fileURL isAudio:(BOOL)isAudio
{
    [self uninitPlayer];
    
    self.url = fileURL;
    
    // iOS 7.0 deprecated
//    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;                
//    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,          
//                             sizeof (audioRouteOverride),&audioRouteOverride);

    // iOS 7.0 audio session setting
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error]) {
        // handle error
        NSLog(@"AVAudioSession error setting category:%@",error);
        
    }
    
    if (![session setActive:YES error:&error])
    {
        NSLog(@"AVAudioSession error activating: %@",error);
    }
    
    if (![session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error]){
        
        NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
    }
    
    AVPlayerItem *playerItem = nil;
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
		playerItem = [AVPlayerItem playerItemWithURL:fileURL];
	} else {
		AVAsset *asset = [AVAsset assetWithURL:fileURL];
		playerItem = [AVPlayerItem playerItemWithAsset:asset];
	}
    AVAsset *playItemAsset = playerItem.asset;
    NSArray * videoTracks = [playItemAsset tracksWithMediaType:AVMediaTypeVideo];
    if (![videoTracks count])
        return;
    
    AVAssetTrack * videoTrack = [videoTracks objectAtIndex:0];
    _txf = [videoTrack preferredTransform];
    _naturalSize = [videoTrack naturalSize];
    _isRotated = (_txf.b != 0.0f) && (_txf.c != 0.0f);
    
    CGSize presentSize = _isRotated ? CGSizeMake(_naturalSize.height, _naturalSize.width) : _naturalSize;
    
    _frameRate = videoTrack.nominalFrameRate;
    _avgFrameDuration = 1.0f / _frameRate;
    _cmTimeDelta = CMTimeMakeWithSeconds(1 * _avgFrameDuration / 2.0f, 1);
    
    _durationCM = playItemAsset.duration;
    _durationF = CMTimeGetSeconds(_durationCM);
    
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerDidReachedEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
    
    if (m_playerLayer)
    {
        [m_playerLayer removeFromSuperlayer];
        m_playerLayer = nil;
    }

    if (isAudio)
    {
        self.backgroundColor = [UIColor clearColor];
        [self setImage:[UIImage imageNamed:@"voice_memo.png"]];
    } else {
        self.backgroundColor = [UIColor blackColor];

        CGSize viewSize = self.bounds.size;
        
        CGFloat viewHeight = viewSize.width * presentSize.height / (float)presentSize.width;
        if (viewHeight > viewSize.height) {
            CGFloat viewWidth = viewSize.height * presentSize.width / (float)presentSize.height;
            _visibleVideoWidth = (int)viewWidth;
            _visibleVideoHeight = (int)viewSize.height;
        } else {
            _visibleVideoWidth = (int)viewSize.width;
            _visibleVideoHeight = (int)viewHeight;
        }

        NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:3];
        [dictionary setObject:[NSNumber numberWithInteger:kCVPixelFormatType_32ARGB] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
        [dictionary setObject:[NSNumber numberWithInteger:(_isRotated ? _visibleVideoHeight : _visibleVideoWidth)] forKey:(NSString *)kCVPixelBufferWidthKey];
        [dictionary setObject:[NSNumber numberWithInteger:(_isRotated ? _visibleVideoWidth : _visibleVideoHeight)] forKey:(NSString *)kCVPixelBufferHeightKey];
        _playerItemVideoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:dictionary];
        [playerItem addOutput:_playerItemVideoOutput];
        
        if (SELF_DRAW) {
            m_playerLayer = [CALayer layer];
            [m_playerLayer setBackgroundColor:[UIColor blackColor].CGColor];
            [m_playerLayer setContentsGravity:kCAGravityResizeAspect];
        } else {
            m_playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];

            [(AVPlayerLayer *)m_playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        }
        m_playerLayer.frame = self.bounds;
        
        [self.layer addSublayer:m_playerLayer];
    }
    
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    if (SELF_DRAW) {
        _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / _frameRate
                                                         target:self
                                                       selector:@selector(onRefreshTimer2:)
                                                       userInfo:nil
                                                        repeats:YES];
    }
    
    m_isStoped = YES;
}

// slow motion
- (void)replaceSlowMotion:(NSURL *)fileURL
{
    AVURLAsset* videoAsset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
    
    //create mutable composition
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                   preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *videoInsertError = nil;
    BOOL videoInsertResult = [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                                            ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                                             atTime:kCMTimeZero
                                                              error:&videoInsertError];
    if (!videoInsertResult || nil != videoInsertError) {
        //handle error
        return;
    }
    
    //slow down whole video by 2.0
    double videoScaleFactor = 2.0;
    CMTime videoDuration = videoAsset.duration;
    
    [compositionVideoTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, videoDuration)
                               toDuration:CMTimeMake(videoDuration.value*videoScaleFactor, videoDuration.timescale)];
    AVPlayerItem *playerItem =[[AVPlayerItem alloc] initWithAsset:mixComposition];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
}

- (void)play
{
    @synchronized(self)
    {
        if (_bManualSeek)
        {
            [self startManualSeeking];
        } else {
            [self.player play];
        }
        if (self.player)
            m_isStoped = NO;
    }
}

- (void)pause
{
    @synchronized(self)
    {
        if (_bManualSeek)
        {
            [self stopManualSeeking];
        } else {
            [self.player pause];
        }
    }
}

- (void)stop
{
    @synchronized(self)
    {
        if (_bManualSeek)
        {
            [self stopManualSeeking];
        } else {
            [self.player pause];
        }
    }
    CMTime newTime = CMTimeMakeWithSeconds(0, 1);
    [self.player seekToTime:newTime];
    
    m_isStoped = YES;
}

- (BOOL)isPause
{
    if (self.player) {
        @synchronized(self)
        {
            if (_bManualSeek)
            {
                return (_manualSeekTimer == nil);
            } else {
                return (self.player.rate == 0.0f);
            }
        }
    }
    
    return NO;
}

- (void)setLoop:(BOOL)loop
{
    m_isLoop = loop;
}

- (BOOL)isLoop
{
    return m_isLoop;
}

- (void)toggleLoop
{
    m_isLoop = !m_isLoop;
}

- (BOOL)isStopped
{
    return m_isStoped;
}

- (void)setRate:(float)rate
{
    if (_rate > 0.0f && _rate < 0.5f)
    {
        [self stopManualSeeking];
        @synchronized(self)
        {
            _bManualSeek = NO;
        }
    } else {
        [self.player pause];
    }
    
    _rate = rate;
    if (_rate < 0.5f) {
        [self startManualSeeking];
        @synchronized(self)
        {
            _bManualSeek = YES;
        }
        
    } else {
        [self.player setRate:_rate];
        [self.player play];
    }
    
//    NSLog(@"currnts real=%f: virtaul=%f", self.player.rate, _rate);
}

#pragma mark - Playback Slowly(1/4X, 1/8X)
- (void)onManualSeekTimer:(id)sender
{
    if (CMTimeCompare([self.player.currentItem currentTime],[self.player.currentItem duration]) < 0)
    {
        [self.player.currentItem stepByCount:1];
    } else {
        [self stopManualSeeking];
        @synchronized(self)
        {
            _bManualSeek = NO;
        }
        CMTime newTime = CMTimeMakeWithSeconds(0, 1);
        [self.player seekToTime:newTime toleranceBefore:_cmTimeDelta toleranceAfter:_cmTimeDelta];
        if (m_isLoop)
        {
            [self startManualSeeking];
            @synchronized(self)
            {
                _bManualSeek = YES;
            }
        } else {
            m_isStoped = YES;
        }
    }
}

- (void)startManualSeeking
{
    _manualSeekTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f / 30.0f / _rate
                                                        target:self
                                                      selector:@selector(onManualSeekTimer:)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)stopManualSeeking
{
    [_manualSeekTimer invalidate];
    _manualSeekTimer = nil;
}

#pragma mark - Playback Time
- (float)duration
{
//    return CMTimeGetSeconds(self.player.currentItem.duration);
    return _durationF;
}

- (float)currentTime
{
    return CMTimeGetSeconds(self.player.currentItem.currentTime);
}

#pragma mark - Seek
- (void)seekToTime:(float)seekTime
{
    CMTime cmTimeToSeek = CMTimeMakeWithSeconds(1 * seekTime, 1);
    
    [self.player seekToTime:cmTimeToSeek toleranceBefore:_cmTimeDelta toleranceAfter:_cmTimeDelta];
    [self.player  play];
    [self.player pause];
}

- (void)stepByCount:(int)stepCount
{
    [self.player.currentItem stepByCount:stepCount];
    
    if ((stepCount > 0) && CMTimeCompare([self.player.currentItem currentTime],[self.player.currentItem duration]) >= 0)
    {
        [self seekToTime:0];
        usleep(1000);
    }
    
    if ((stepCount < 0) && CMTimeCompare([self.player.currentItem currentTime],kCMTimeZero) <= 0)
    {
        [self seekToTime:_durationF];
        usleep(1000);
    }
    
    if (SELF_DRAW) {
        [self drawFrame];
    }
}

#pragma mark -
- (void)onRefreshTimer2:(id)sender
{
    [self drawFrame];
}

+ (CGContextRef)createBitmapContextOfSize:(CGSize)size {
	CGContextRef    context = NULL;
	CGColorSpaceRef colorSpace;
	int             bitmapByteCount;
	int             bitmapBytesPerRow;
	
	bitmapBytesPerRow   = (size.width * 4);
	bitmapByteCount     = (bitmapBytesPerRow * size.height);
	colorSpace = CGColorSpaceCreateDeviceRGB();
    
	context = CGBitmapContextCreate (NULL,
									 size.width,
									 size.height,
									 8,      // bits per component
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedFirst);
	
	CGContextSetAllowsAntialiasing(context,NO);
	if (context== NULL) {
		return NULL;
	}
	CGColorSpaceRelease( colorSpace );
	
	return context;
}

- (CGImageRef) cgImageFromPixelBuffer:(CVPixelBufferRef)imageBuffer
{
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    //////Rotate//////////
    CGSize presentSize = _isRotated ? CGSizeMake(height, width): CGSizeMake(width, height);
    
    CGContextRef context1 = CGBitmapContextCreate(NULL, presentSize.width, presentSize.height,
                                                  8,
                                                  4 * presentSize.width,
                                                  CGImageGetColorSpace(quartzImage),
                                                  kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedFirst);
    
    if (_isRotated) {
        CGAffineTransform cat = CGAffineTransformMake(-1, 0, 0, -1, presentSize.width, presentSize.height);
        _txf.tx = presentSize.width;
        cat = CGAffineTransformConcat(_txf, cat);
        CGContextConcatCTM(context1, cat);
    }
    
    CGContextDrawImage(context1, CGRectMake(0, 0, _isRotated ? presentSize.height : presentSize.width, _isRotated ? presentSize.width : presentSize.height), quartzImage);
    CGImageRef orientedImage = CGBitmapContextCreateImage(context1);
    
    CGImageRelease(quartzImage);
    CGContextRelease(context1);
    
    return orientedImage;
}

- (void)drawFrame
{
    CVPixelBufferRef pixelBuffer = [_playerItemVideoOutput copyPixelBufferForItemTime:self.player.currentTime itemTimeForDisplay:NULL];
    if (pixelBuffer) {
        CGImageRef videoImage = [self cgImageFromPixelBuffer:pixelBuffer];
        if (videoImage)
        {
            [CATransaction begin];
            [m_playerLayer setContents:(__bridge id)(videoImage)];
            [CATransaction commit];

            CGImageRelease(videoImage);
        }
        
        CVPixelBufferRelease(pixelBuffer);
    }
}

- (CGImageRef)getCurrentFrame
{
    CGImageRef videoImage = NULL;
    CVPixelBufferRef pixelBuffer = [_playerItemVideoOutput copyPixelBufferForItemTime:self.player.currentTime itemTimeForDisplay:NULL];
    if (pixelBuffer) {
        videoImage = [self cgImageFromPixelBuffer:pixelBuffer];
        CVPixelBufferRelease(pixelBuffer);
    }
    
    return videoImage;
}

- (float)ratioWidthtoHeight
{
//    int width = _isRotated ? _visibleVideoHeight : _visibleVideoWidth;
//    int height = _isRotated ? _visibleVideoWidth : _visibleVideoHeight;
//    return (float)width/(float)height;

    CGSize presentSize = _isRotated ? CGSizeMake(_naturalSize.height, _naturalSize.width) : _naturalSize;
    return (float)presentSize.width/(float)presentSize.height;
}

@end
