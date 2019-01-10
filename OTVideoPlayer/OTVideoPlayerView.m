//
//  OTVideoPlayerView.m
//  OTVideoPlayerDemo
//
//  Created by irobbin on 2018/2/26.
//  Copyright © 2018年 irobbin.com. All rights reserved.
//

#import "OTVideoPlayerView.h"

#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@import AVFoundation;

inline static bool isFloatZero(float value)
{
    return fabsf(value) <= 0.00001f;
}

@interface OTVideoPlayerView() {
    BOOL _isPlayByCall;
}

@property (nonatomic, strong) AVURLAsset * playAsset;
@property (nonatomic, strong) AVPlayerItem * playerItem;
@property (nonatomic, strong) AVPlayer * player;
@property (nonatomic, assign) OTVideoLoadState loadState;

@property (nonatomic, readwrite)  NSTimeInterval duration;
@property (nonatomic, readwrite)  NSTimeInterval loadedDuration;
// 加载的数据还有多少秒可以播放
@property (nonatomic, readwrite)  NSTimeInterval loadedCanPlayDuration;

// 如果外部调用了暂停方法，那么值为 YES，否则为NO。
// 目的就是为了准确返回isPlaying的状态
@property (nonatomic, assign) BOOL pauseByCall;
@property (nonatomic, assign) BOOL isCallFirstFrame;
@property (nonatomic, assign) BOOL isPlayComplete;
@property (nonatomic, assign) BOOL isSeeking;
@property (nonatomic, assign) BOOL isPrerolling;
@property (nonatomic, assign) BOOL playingBeforeInterruption;
@property (nonatomic, assign) NSTimeInterval seekingTime;
@property (nonatomic, strong) id playbackTimeObserver;
@property (nonatomic, strong) id timerObserver;
@property (nonatomic, assign) CMTime timeWhenEnterBackground;


@end

@implementation OTVideoPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (void)dealloc {
    [_player removeObserver:self forKeyPath:@"rate"];
    [self removeKVOForPlayerItem:_playerItem];
    [self removeNotification];
    [self removeFirstFrameKVO];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.playbackVolume = 1.0;
        self.backgroundColor = [UIColor blackColor];
        self.timeWhenEnterBackground = kCMTimeInvalid;
        self.pauseByCall = YES;
        [self addNotification];
        
        [self addFirstFrameKVO];
    }
    return self;
}

- (void)setupWithURL:(NSURL *)videoURL shouldAutoPlay:(BOOL)shouldAutoPlay {
    if (videoURL == nil || videoURL.absoluteString.length <= 0) {
        return ;
    }
    
    // 配置播放模式并抢夺播放资源
//    [[XYAudioKit sharedInstance] setupAudioSession];
    
    self.isPlayComplete = NO;
    self.isPrerolling = NO;
    self.isSeeking = NO;
    self.shouldAutoplay = shouldAutoPlay;
    self.isCallFirstFrame = NO;
    
    self.videoURL = videoURL;
    [self removePlayCallback];
    
    self.playAsset = [AVURLAsset URLAssetWithURL:self.videoURL options:nil];
    
    // remove kvo for player item
    [self removeKVOForPlayerItem:self.playerItem];
    // remove notification for player item
    [self removeNotificationForPlayerItem:self.playerItem];
    
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.playAsset];
    // add kvo for player item
    [self addKVOForPlayerItem:self.playerItem];
    // add notification player item
    [self addNotificationForPlayerItem:self.playerItem];
    if (SYSTEM_VERSION_LESS_THAN(@"10.0")) {
        [self.player removeObserver:self forKeyPath:@"rate"];
        self.player = nil;
    }
    
    if (self.player == nil) {
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        if (@available(iOS 10, *)) {
            self.player.automaticallyWaitsToMinimizeStalling = NO;
        }
        
        
        [self.player addObserver:self
                      forKeyPath:@"rate"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:NULL];
    }
    if (self.player.currentItem != self.playerItem) {
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    }
    
    self.player.volume = self.playbackVolume;
    self.player.muted = self.muted;
    
    AVPlayerLayer * playerLayer = (AVPlayerLayer *)self.layer;
    playerLayer.videoGravity = [self playerLayerGravityWithScalingMode:self.scalingMode];
    playerLayer.player = self.player;
    
    [self afterWhenPlayItemDidReplace];
    
    if (self.controlView && [self.controlView respondsToSelector:@selector(videoPlayerDidSetupWithURL:)]) {
        [self.controlView videoPlayerDidSetupWithURL:self.videoURL];
    }
}

- (void)setupWithURL:(NSURL *)videoURL {
    [self setupWithURL:videoURL shouldAutoPlay:YES];
}

#pragma mark - Public Funs

- (void)play {
    if (self.isPlayComplete){
        self.isPlayComplete = NO;
        [self.player seekToTime:kCMTimeZero];
    }
    
    [self.player play];
    _isPlayByCall = YES;
    self.pauseByCall = NO;
}

- (void)pause {
    [_player pause];
    self.isPrerolling = NO;
    self.pauseByCall = YES;
}

- (void)stop {
    [_player pause];
    self.isPlayComplete = YES;
}

- (void)reset {
    if (self.player == nil) {
        return ;
    }
    
    [self stop];
    [self removeKVOForPlayerItem:self.playerItem];
    [self removeNotificationForPlayerItem:self.playerItem];

    if (self.playerItem != nil) {
        [self.playerItem cancelPendingSeeks];
        self.playerItem = nil;
    }
    
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.isCallFirstFrame = NO;
    self.duration = 0;
    self.loadedDuration = 0;
    self.isPlayComplete = NO;
    self.isSeeking = NO;
    self.isPrerolling = NO;
    self.seekingTime = 0.f;
    self.callbackInterval = kCMTimeZero;
    self.shouldAutoplay = NO;
    self.pauseByCall = YES;
    self.loadState = OTVideoLoadStateUnknown;
    self.loadedCanPlayDuration = 0.;
    self.muted = NO;
    self.playbackVolume = 1.0;
    _isPlayByCall = NO;
    [self removePlayCallback];
}

- (BOOL)isPlayByCall {
    return _isPlayByCall;
}

- (BOOL)isPlaying {
    if (!isFloatZero(_player.rate)) {
        return YES;
    } else {
        
        if (_pauseByCall) {
            return NO;
        }
        
        if (_isPrerolling) {
            return YES;
        } else {
            return NO;
        }
    }
}

- (UIImage *)thumbnailImageAtCurrentTime {
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:_playAsset];
    CMTime expectedTime = _playerItem.currentTime;
    CGImageRef cgImage = NULL;
    
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    cgImage = [imageGenerator copyCGImageAtTime:expectedTime actualTime:NULL error:NULL];
    
    if (!cgImage) {
        imageGenerator.requestedTimeToleranceBefore = kCMTimePositiveInfinity;
        imageGenerator.requestedTimeToleranceAfter = kCMTimePositiveInfinity;
        cgImage = [imageGenerator copyCGImageAtTime:expectedTime actualTime:NULL error:NULL];
    }
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    return image;
}

#pragma mark - Private Funs

- (void)afterWhenPlayItemDidReplace {
    if (self.shouldAutoplay && ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)) {
        [self.player play];
    }
}

- (void)callPlayError:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayer:errorOccur:)]) {
        [self.delegate videoPlayer:self errorOccur:error];
    }
    [self callPlaybackStateChange];
    [self callLoadStateChange];
}

- (void)callLoadStateChange {
    if (self.delegate && [self.delegate respondsToSelector:@selector(loadStateDidChangeForVideoPlayer:)]) {
        [self.delegate loadStateDidChangeForVideoPlayer:self];
    }
}

- (void)callPlaybackStateChange {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playbackStateDidChangeForVideoPlayer:)]) {
        [self.delegate playbackStateDidChangeForVideoPlayer:self];
    }
}

- (void)setupPlayCallback {

    if (CMTIME_IS_INVALID(self.callbackInterval)) {
        return ;
    }
    
    if (CMTimeCompare(self.callbackInterval, kCMTimeZero) <= 0) {
        return ;
    }
    
    [self removePlayCallback];
    
    __weak OTVideoPlayerView * weakSelf = self;
    self.playbackTimeObserver =  [self.player addPeriodicTimeObserverForInterval:self.callbackInterval queue:dispatch_get_main_queue() usingBlock:^(CMTime time){
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(playCallbackForVideoPlayer:)]) {
            [weakSelf.delegate playCallbackForVideoPlayer:weakSelf];
        }
    }];
}
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
}

- (void)removePlayCallback {
    if (self.playbackTimeObserver) {
        [self.player removeTimeObserver:self.playbackTimeObserver];
        self.playbackTimeObserver = nil;
    }
}

- (AVLayerVideoGravity)playerLayerGravityWithScalingMode:(OTVideoScalingMode)scalingMode {
    switch (scalingMode) {
        case OTVideoScalingModeFill:
            return AVLayerVideoGravityResize;
            break;
        case OTVideoScalingModeNone:
            return AVLayerVideoGravityResizeAspect;
            break;
        case OTVideoScalingModeAspectFit:
            return AVLayerVideoGravityResizeAspect;
            break;
        case OTVideoScalingModeAspectFill:
            return AVLayerVideoGravityResizeAspectFill;
            break;
        default:
            break;
    }
}

- (void)didPlayableDurationUpdate {
    NSTimeInterval currentPlaybackTime = self.currentPlaybackTime;
    int playableDurationMilli    = (int)(self.loadedDuration * 1000);
    int currentPlaybackTimeMilli = (int)(currentPlaybackTime * 1000);
    
    int bufferedDurationMilli = playableDurationMilli - currentPlaybackTimeMilli;
    if (bufferedDurationMilli > 3000 && self.isPlaying) {
        self.player.rate = 1.0;
    }
    
    CMTime time = _playerItem.duration;
    Float64 seconds = CMTimeGetSeconds(time);
    BOOL isBufferFull = (seconds > 0 && playableDurationMilli >= (int)(seconds *1000));
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didPlayableDurationUpdate:playableDuration:)]) {
        [self.delegate didPlayableDurationUpdate:self playableDuration:self.loadedDuration];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XYNotificationBufferedDurationMilliUpdate"
                                                        object:self
                                                      userInfo:@{@"bufferedDurationMilli" : @(bufferedDurationMilli), @"videoURL" : self.videoURL, @"isBufferFull":@(isBufferFull)}];
}

- (void)addFirstFrameKVO {
    AVPlayerLayer * playerLayer = (AVPlayerLayer *)self.layer;
    [playerLayer addObserver:self forKeyPath:@"readyForDisplay" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
}

- (void)removeFirstFrameKVO {
    AVPlayerLayer * playerLayer = (AVPlayerLayer *)self.layer;
    [playerLayer removeObserver:self forKeyPath:@"readyForDisplay"];
}

#pragma mark - KVO

- (void)addKVOForPlayerItem:(AVPlayerItem *)playerItem {
    [self.playerItem addObserver:self
                      forKeyPath:@"status"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:NULL];
    
    [self.playerItem addObserver:self
                      forKeyPath:@"loadedTimeRanges"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:NULL];
    
    [self.playerItem addObserver:self
                      forKeyPath:@"playbackLikelyToKeepUp"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:NULL];
    
    [self.playerItem addObserver:self
                      forKeyPath:@"playbackBufferEmpty"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:NULL];
    
    [self.playerItem addObserver:self
                      forKeyPath:@"playbackBufferFull"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:NULL];
    
}

- (void)removeKVOForPlayerItem:(AVPlayerItem *)playerItem {
    if (playerItem) {
        [playerItem removeObserver:self forKeyPath:@"status"];
        [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [playerItem removeObserver:self forKeyPath:@"playbackBufferFull"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
            case AVPlayerItemStatusUnknown: {
                break;
            }
            case AVPlayerItemStatusReadyToPlay: {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                NSTimeInterval duration = CMTimeGetSeconds(playerItem.duration);
                
                if (duration <= 0) {
                    self.duration = 0.0f;
                } else {
                    self.duration = duration;
                }

                if (self.delegate && [self.delegate respondsToSelector:@selector(readyToPlayForVideoPlayer:)]) {
                    [self.delegate readyToPlayForVideoPlayer:self];
                }
                
                [self setupPlayCallback];
                
                break;
            }
            case AVPlayerItemStatusFailed: {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self callPlayError:playerItem.error];
                
                break;
            }
        }
        
        [self callPlaybackStateChange];
        [self callLoadStateChange];
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        if (_player != nil && playerItem.status == AVPlayerItemStatusReadyToPlay) {
            NSArray *timeRangeArray = playerItem.loadedTimeRanges;
            CMTime currentTime = [_player currentTime];
            
            BOOL foundRange = NO;
            CMTimeRange aTimeRange = {0};
            
            if (timeRangeArray.count) {
                aTimeRange = [[timeRangeArray objectAtIndex:0] CMTimeRangeValue];
                if(CMTimeRangeContainsTime(aTimeRange, currentTime)) {
                    foundRange = YES;
                }
            }
            
            if (foundRange) {
                CMTime maxTime = CMTimeRangeGetEnd(aTimeRange);
                NSTimeInterval playableDuration = CMTimeGetSeconds(maxTime);
                if (playableDuration > 0) {
                    self.loadedDuration = playableDuration;
                    [self didPlayableDurationUpdate];
                    
                    
                    // 计算加载进度
                    if (playableDuration / CMTimeGetSeconds(self.playerItem.duration) >= 0.99) {
                        // 全部加在完成
                        self.loadState = OTVideoLoadStatePlayable | OTVideoLoadStatePlaythroughOK;
                    }
                    // 计算可以播放的时长
                    self.loadedCanPlayDuration = playableDuration - CMTimeGetSeconds(self.player.currentTime);
                    // 时间长过2s，开始播放
                    if (self.loadedCanPlayDuration > 2.0 && self.isPlaying) {
                        self.loadState = self.loadState | OTVideoLoadStatePlayable;
                        [self play];
                    }
                }
            }
        } else {
            self.loadedDuration = 0;
        }
        
        
        [self callLoadStateChange];
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        if (self.playerItem.isPlaybackBufferEmpty) {
            self.isPrerolling = YES;
            self.loadState = OTVideoLoadStateStalled;
        }
        
        [self callLoadStateChange];
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        if (self.playerItem.playbackLikelyToKeepUp) {
            self.loadState = OTVideoLoadStatePlayable;
        }
        
        [self callLoadStateChange];
    } else if ([keyPath isEqualToString:@"playbackBufferFull"]) {
        if (self.playerItem.playbackBufferFull) {
            self.loadState = OTVideoLoadStatePlayable;
        }
        
        [self callLoadStateChange];
    } else if ([keyPath isEqualToString:@"rate"]) {
        if (self.player != nil && !isFloatZero(self.player.rate))
            self.isPrerolling = NO;
        
        [self callPlaybackStateChange];
    } else if ([keyPath isEqualToString:@"readyForDisplay"]) {
        if (change[@"new"]) {
            BOOL readyForDisplay = [change[@"new"] boolValue];
            if (readyForDisplay) {
                if (!self.isCallFirstFrame) {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(firstVideoFrameDidShowForVideoPlayer:)]) {
                        [self.delegate firstVideoFrameDidShowForVideoPlayer:self];
                        self.isCallFirstFrame = YES;
                    }
                }
            }
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Notification

- (void)addNotificationForPlayerItem:(AVPlayerItem *)playerItem {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
}

- (void)removeNotificationForPlayerItem:(AVPlayerItem *)playerItem {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionInterrupt:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:nil];

}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 音频资源被打断，比如来电话
 
 @param notification notification
 */
- (void)audioSessionInterrupt:(NSNotification *)notification
{
    int reason = [[[notification userInfo] valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    switch (reason) {
        case AVAudioSessionInterruptionTypeBegan: {
            switch (self.playbackState) {
                case OTVideoPlaybackStateStopped:
                case OTVideoPlaybackStatePaused:
                    self.playingBeforeInterruption = NO;
                    break;
                default:
                    self.playingBeforeInterruption = YES;
                    break;
            }
            [self pause];
//            [[OTAudioKit sharedInstance] setActive:NO];
            break;
        }
        case AVAudioSessionInterruptionTypeEnded: {
            NSDictionary *info = notification.userInfo;
            AVAudioSessionInterruptionOptions options =[info[AVAudioSessionInterruptionOptionKey] integerValue];
//            [[OTAudioKit sharedInstance] setActive:YES];
            if (self.playingBeforeInterruption && options == AVAudioSessionInterruptionOptionShouldResume) {
                [self play];
            }
            break;
        }
    }
}

- (void)appDidEnterBackground:(NSNotification *)notification {
    if (self.player) {
        if (self.isPlaying) {
            [self pause];
            self.timeWhenEnterBackground = self.player.currentTime;
        } else {
            self.timeWhenEnterBackground = kCMTimeInvalid;
        }
    } else {
        self.timeWhenEnterBackground = kCMTimeInvalid;
    }
}

- (void)appWillEnterForeground:(NSNotification *)notification {
    if (CMTimeCompare(kCMTimeInvalid, self.timeWhenEnterBackground) == 0) {
        return ;
    }
    
    if (!self.player) {
        return;
    }
    
    @try {
        [self.player seekToTime:self.timeWhenEnterBackground
                toleranceBefore:kCMTimeZero
                 toleranceAfter:kCMTimeZero
              completionHandler:^(BOOL finished) {
                  
            if (finished) {
                [self play];
            }
        }];
    } @catch (NSException *exception) {
        [self play];
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    if (notification.object == self.playerItem) {
        self.isPlayComplete = YES;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(playReachToEndForVideoPlayer:)]) {
        [self.delegate playReachToEndForVideoPlayer:self];
    }
    
    [self callPlaybackStateChange];
    [self callLoadStateChange];
    
}

#pragma mark - Getter & Setter

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    if (_player) {
        _player.muted = muted;
    }
}

- (void)setScalingMode:(OTVideoScalingMode)scalingMode {
    _scalingMode = scalingMode;
    AVPlayerLayer * playerLayer = (AVPlayerLayer *)self.layer;
    playerLayer.videoGravity = [self playerLayerGravityWithScalingMode:_scalingMode];
}

- (OTVideoPlaybackState)playbackState {
    if (!_player)
        return OTVideoPlaybackStateStopped;
    
    OTVideoPlaybackState mpState = OTVideoPlaybackStateStopped;
    if (_isPlayComplete) {
        mpState = OTVideoPlaybackStateStopped;
    } else if (_isSeeking) {
        mpState = OTVideoPlaybackStateSeeking;
    } else if ([self isPlaying]) {
        mpState = OTVideoPlaybackStatePlaying;
    } else {
        mpState = OTVideoPlaybackStatePaused;
    }
    return mpState;
}

- (OTVideoLoadState)loadState {
    if (_player == nil)
        return OTVideoLoadStateUnknown;
    
    if (_isSeeking)
        return OTVideoLoadStateStalled;
    
    AVPlayerItem *playerItem = [_player currentItem];
    if (playerItem == nil) {
        return OTVideoLoadStateUnknown;
    }

    if ([self.playerItem isPlaybackBufferFull] ||
        [self.playerItem isPlaybackLikelyToKeepUp]) {
        return _loadState | OTVideoLoadStatePlayable;
    }
    
    return _loadState;
}

- (NSTimeInterval)currentPlaybackTime {
    if (!_player)
        return 0.0f;
    
    if (_isSeeking)
        return _seekingTime;
    
    return CMTimeGetSeconds([_player currentTime]);
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)aCurrentPlaybackTime {
    if (!self.player || (self.loadState & OTVideoLoadStatePlayable == NO))
        return;
    
    self.seekingTime = aCurrentPlaybackTime;
    self.isSeeking = YES;
    [self callPlaybackStateChange];
    [self callLoadStateChange];
    
    [self.player seekToTime:CMTimeMakeWithSeconds(aCurrentPlaybackTime, NSEC_PER_SEC)
          completionHandler:^(BOOL finished) {
              dispatch_async(dispatch_get_main_queue(), ^{
                  self.isSeeking = NO;
                  
                  [self callPlaybackStateChange];
                  [self callLoadStateChange];
              });
          }];
}

- (CGSize)naturalSize {
    if (_playAsset == nil)
        return CGSizeZero;
    
    NSArray<AVAssetTrack *> *videoTracks = [_playAsset tracksWithMediaType:AVMediaTypeVideo];
    if (videoTracks == nil || videoTracks.count <= 0)
        return CGSizeZero;
    
    return [videoTracks objectAtIndex:0].naturalSize;
}

- (void)setControlView:(UIView<OTVideoPlayerBeControlView> *)controlView {
    [_controlView removeFromSuperview];
    _controlView = controlView;
    
    _controlView.frame = self.bounds;
    _controlView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self addSubview:_controlView];
}

- (void)setPlaybackVolume:(float)playbackVolume {
    _playbackVolume = playbackVolume;
    if ( _player ) {
        _player.volume = playbackVolume;
        [self setMuted:playbackVolume < 0.01];
    }
}

@end
