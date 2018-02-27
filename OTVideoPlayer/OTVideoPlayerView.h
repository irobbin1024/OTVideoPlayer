//
//  OTVideoPlayerView.h
//  OTVideoPlayerDemo
//
//  Created by irobbin on 2018/2/26.
//  Copyright © 2018年 irobbin.com. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;

NS_ASSUME_NONNULL_BEGIN

@class OTVideoPlayerView;

typedef NS_ENUM(NSInteger, OTVideoPlaybackState) {
    OTVideoPlaybackStateStopped,
    OTVideoPlaybackStatePlaying,
    OTVideoPlaybackStatePaused,
    OTVideoPlaybackStateSeeking,
};

typedef NS_ENUM(NSInteger, OTVideoLoadState) {
    OTVideoLoadStateUnknown        = 0,
    OTVideoLoadStatePlayable       = 1 << 0,
    OTVideoLoadStatePlaythroughOK  = 1 << 1, // Playback will be automatically started in this state when shouldAutoplay is YES
    OTVideoLoadStateStalled        = 1 << 2, // Playback will be automatically paused in this state, if started
};

typedef NS_ENUM(NSInteger, OTVideoScalingMode) {
    OTVideoScalingModeNone,
    OTVideoScalingModeAspectFit,
    OTVideoScalingModeAspectFill,
    OTVideoScalingModeFill,
};

@protocol OTVideoPlayerBeControlView <NSObject>

@optional

- (void)setupWithURL:(NSURL *)url;
@property (nonatomic, weak) OTVideoPlayerView * playerView;


@end

@protocol OTVideoPlayerDelegate <NSObject>

@optional

- (void)readyToPlayForVideoPlayer:(OTVideoPlayerView *)videoPlayer;
- (void)playbackStateDidChangeForVideoPlayer:(OTVideoPlayerView *)videoPlayer;
- (void)loadStateDidChangeForVideoPlayer:(OTVideoPlayerView *)videoPlayer;
- (void)videoPlayer:(OTVideoPlayerView *)videoPlayer errorOccur:(NSError *)error;
- (void)playReachToEndForVideoPlayer:(OTVideoPlayerView *)videoPlayer;
- (void)playCallbackForVideoPlayer:(OTVideoPlayerView *)videoPlayer;
- (void)firstVideoFrameDidShowForVideoPlayer:(OTVideoPlayerView *)videoPlayer;

@end

@interface OTVideoPlayerView : UIView

@property (nonatomic, readonly)  OTVideoPlaybackState playbackState;
@property (nonatomic, readonly)  OTVideoLoadState loadState;
@property (nonatomic, readonly)  NSTimeInterval duration;
@property (nonatomic, readonly)  NSTimeInterval playableDuration;
@property (nonatomic, readonly)  NSInteger bufferingProgress;
@property (nonatomic, readonly)  CGSize naturalSize;

@property (nonatomic, assign)   NSTimeInterval currentPlaybackTime;
@property (nonatomic, assign)   OTVideoScalingMode scalingMode;
@property (nonatomic, assign)   BOOL shouldAutoplay;
@property (nonatomic, assign)   float playbackRate;
@property (nonatomic, assign)   float playbackVolume;

@property (nonatomic, weak)     id<OTVideoPlayerDelegate> delegate;
@property (nonatomic, strong)   UIView<OTVideoPlayerBeControlView> * controlView;
@property (nonatomic, assign)   CMTime callbackInterval;


- (void)setupWithURL:(NSURL *)videoURL;
- (void)play;
- (void)pause;
- (void)stop;
- (void)reset;
- (BOOL)isPlaying;

- (UIImage *)thumbnailImageAtCurrentTime;

@end

NS_ASSUME_NONNULL_END
