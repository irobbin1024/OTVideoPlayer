//
//  OTVideoPlayerView.h
//  OTVideoPlayerDemo
//
//  Created by irobbin on 2018/2/26.
//  Copyright © 2018年 irobbin.com. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OTVideoPlaybackState) {
    OTVideoPlaybackStateNormal,
};

typedef NS_ENUM(NSInteger, OTVideoLoadState) {
    OTVideoLoadStateStopped,
    OTVideoLoadStatePlaying,
    OTVideoLoadStatePaused,
    OTVideoLoadStateInterrupted,
    OTVideoLoadStateSeekingForward,
    OTVideoLoadStateSeekingBackward
};

typedef NS_ENUM(NSInteger, OTVideoScalingMode) {
    OTVideoScalingModeNone,
    OTVideoScalingModeAspectFit,
    OTVideoScalingModeAspectFill,
    OTVideoScalingModeFill,
};

@interface OTVideoPlayerView : UIView

@property (nonatomic, readonly)  OTVideoPlaybackState playbackState;
@property (nonatomic, readonly)  OTVideoLoadState loadState;
@property (nonatomic, readonly)  NSTimeInterval duration;
@property (nonatomic, readonly)  NSTimeInterval playableDuration;
@property (nonatomic, readonly)  NSInteger bufferingProgress;
@property (nonatomic, readonly)  CGSize naturalSize;

@property (nonatomic, assign)    NSTimeInterval currentPlaybackTime;
@property (nonatomic, assign)    OTVideoScalingMode scalingMode;
@property (nonatomic, assign)    BOOL shouldAutoplay;
@property (nonatomic, assign)    float playbackRate;
@property (nonatomic, assign)    float playbackVolume;


- (void)setupWithURL:(NSURL *)videoURL;
- (void)play;
- (void)pause;
- (void)stop;
- (void)reset;
- (BOOL)isPlaying;

- (UIImage *)thumbnailImageAtCurrentTime;

@end
