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

typedef NS_OPTIONS(NSInteger, OTVideoLoadState) {
    OTVideoLoadStateUnknown        = 1 << 0,
    OTVideoLoadStatePlayable       = 1 << 1,
    OTVideoLoadStatePlaythroughOK  = 1 << 2,
    OTVideoLoadStateStalled        = 1 << 3,
};

typedef NS_ENUM(NSInteger, OTVideoScalingMode) {
    OTVideoScalingModeNone,
    OTVideoScalingModeAspectFit,
    OTVideoScalingModeAspectFill,
    OTVideoScalingModeFill,
};

@protocol OTVideoPlayerBeControlView <NSObject>

@optional

/**
 当播放器调用setup方法时，controlView就会收到回调

 @param url url
 */
- (void)videoPlayerDidSetupWithURL:(NSURL *)url;

/**
 播放器handler
 */
@property (nonatomic, weak) OTVideoPlayerView * playerView;


@end

@protocol OTVideoPlayerDelegate <NSObject>

@optional

/**
 准备播放，但是不保证此时有视频画面输出

 @param videoPlayer videoPlayer
 */
- (void)readyToPlayForVideoPlayer:(OTVideoPlayerView *)videoPlayer;

/**
 播放状态改变的回调

 @param videoPlayer videoPlayer
 */
- (void)playbackStateDidChangeForVideoPlayer:(OTVideoPlayerView *)videoPlayer;

/**
 加载状态改变的回调

 @param videoPlayer videoPlayer
 */
- (void)loadStateDidChangeForVideoPlayer:(OTVideoPlayerView *)videoPlayer;

/**
 播放出现错误

 @param videoPlayer videoPlayer
 @param error NSError
 */
- (void)videoPlayer:(OTVideoPlayerView *)videoPlayer errorOccur:(NSError *)error;

/**
 播放完成，画面停留在最后一帧

 @param videoPlayer videoPlayer
 */
- (void)playReachToEndForVideoPlayer:(OTVideoPlayerView *)videoPlayer;

/**
 定时回调，时间由外部设置，不设置，没有回调

 @param videoPlayer videoPlayer
 */
- (void)playCallbackForVideoPlayer:(OTVideoPlayerView *)videoPlayer;

/**
 第一帧的回调，此时有画面出现

 @param videoPlayer videoPlayer
 */
- (void)firstVideoFrameDidShowForVideoPlayer:(OTVideoPlayerView *)videoPlayer;

/**
 缓存时长变化的回调

 @param videoPlayer videoPlayer
 @param playableDuration 单位秒
 */
- (void)didPlayableDurationUpdate:(OTVideoPlayerView *)videoPlayer playableDuration:(NSTimeInterval)playableDuration;

@end

@interface OTVideoPlayerView : UIView

/**
 reset操作是否被锁住
 */
@property (readonly) BOOL isLockReset;

/**
 视频URL，一般通过setup方法传入
 */
@property (nonatomic, strong) NSURL * videoURL;

/**
 播放状态，在接收-playbackStateDidChangeForVideoPlayer:回调后主动获取
 */
@property (nonatomic, readonly) OTVideoPlaybackState playbackState;

/**
 播放状态，在接收-playbackStateDidChangeForVideoPlayer:回调后主动获取
 */
@property (nonatomic, readonly) OTVideoLoadState loadState;

/**
 视频长度，单位秒
 */
@property (nonatomic, readonly) NSTimeInterval duration;

/**
 已经加载的长度，一般等于缓存到本地时长，单位秒
 */
@property (nonatomic, readonly) NSTimeInterval loadedDuration;

/**
 视频原始大小，-readyToPlayForVideoPlayer:回调之后就可以获取了
 */
@property (nonatomic, readonly) CGSize naturalSize;

/**
 当前播放时间，-playCallbackForVideoPlayer:回调之后可以获取用来设置播放进度条
 */
@property (nonatomic, assign) NSTimeInterval currentPlaybackTime;

/**
 缩放模式
 */
@property (nonatomic, assign) OTVideoScalingMode scalingMode;

/**
 当setup之后，是否应该自动开始播放
 */
@property (nonatomic, assign) BOOL shouldAutoplay;

/**
 静音
 */
@property (nonatomic, assign, getter=isMuted) BOOL muted;

/**
 音量
 */
@property (nonatomic, assign) float playbackVolume;


/**
 代理
 */
@property (nonatomic, weak, nullable) id<OTVideoPlayerDelegate> delegate;

/**
 controlView将会覆盖在OTVideoPlayerView之上
 */
@property (nonatomic, strong, nullable) UIView<OTVideoPlayerBeControlView> * controlView;

/**
 -playCallbackForVideoPlayer: 的回调间隔
 */
@property (nonatomic, assign) CMTime callbackInterval;


/**
 传入url并开始初始化

 @param videoURL 视频地址
 */
- (void)setupWithURL:(NSURL *)videoURL;
- (void)setupWithURL:(NSURL *)videoURL shouldAutoPlay:(BOOL)shouldAutoPlay;

- (void)play;
- (void)pause;

/**
 停止播放，再次调用play会从0开始播放
 */
- (void)stop;

/**
 复原操作
 */
- (void)reset;

/**
 当前是否是播放状态，加载中也算播放状态

 @return BOOL
 */
- (BOOL)isPlaying;

/**
 只要外部调用了play方法，那么返回YES

 @return BOOL
 */
- (BOOL)isPlayByCall;


/**
 当前时间点的缩略图

 @return UIImage
 */
- (UIImage *)thumbnailImageAtCurrentTime;

/**
 锁住reset，防止播放过程中被意外reset
 */
- (void)lockReset;

/**
 解锁reset
 */
- (void)unlockReset;

@end

NS_ASSUME_NONNULL_END
