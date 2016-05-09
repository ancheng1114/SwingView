//
//  AVPlayerView.h
//  AddMusic
//
//  Created by li taixu on 2/22/13.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef enum _PLAYBACK_RATE_TYPE {
    PLAYBACK_RATE_NORMAL = 0,
    PLAYBACK_RATE_1_8,
    PLAYBACK_RATE_1_4,
    PLAYBACK_RATE_1_2,
} PLAYBACK_RATE_TYPE;

@interface AVPlayerView : UIImageView
{
    CALayer *m_playerLayer;
    BOOL m_isLoop;
    BOOL m_isStoped;
}

@property(nonatomic, strong) AVPlayer *     player;
@property (nonatomic ,strong) NSURL *url;

- (void)setFilePath:(NSString *)filePath isAudio:(BOOL)isAudio;
- (void)setFileURL:(NSURL *)fileURL isAudio:(BOOL)isAudio;

- (void)uninitPlayer;

- (void)play;
- (void)pause;
- (void)stop;
- (BOOL)isPause;
- (BOOL)isStopped;

- (void)setLoop:(BOOL)loop;
- (BOOL)isLoop;
- (void)toggleLoop;

- (void)setRate:(float)rate;

- (float)duration;
- (float)currentTime;

- (void)seekToTime:(float)seekTime;
- (void)stepByCount:(int)stepCount;

- (CGImageRef)getCurrentFrame;
- (float)ratioWidthtoHeight;

@end
