//
//  OTVideoPlayerView.m
//  OTVideoPlayerDemo
//
//  Created by irobbin on 2018/2/26.
//  Copyright © 2018年 irobbin.com. All rights reserved.
//

#import "OTVideoPlayerView.h"
@import AVFoundation;

inline static bool isFloatZero(float value)
{
    return fabsf(value) <= 0.00001f;
}

@interface OTVideoPlayerView()

@property (nonatomic, strong) NSURL * videoURL;
@property (nonatomic, strong) AVURLAsset * playAsset;
@property (nonatomic, strong) AVPlayerItem * playerItem;
@property (nonatomic, strong) AVPlayer * player;

@property (nonatomic, readwrite)  NSTimeInterval duration;
@property (nonatomic, readwrite)  NSTimeInterval playableDuration;

@property (nonatomic, assign) BOOL isPlayComplete;
@property (nonatomic, assign) BOOL isSeeking;
@property (nonatomic, assign) BOOL isPrerolling;
@property (nonatomic, assign) NSTimeInterval seekingTime;
@property (nonatomic, strong) id playbackTimeObserver;
@property (nonatomic, strong) id timerObserver;


@end

@implementation OTVideoPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (void)dealloc {
    [_player removeObserver:self forKeyPath:@"rate"];
    [self removeKVOForPlayerItem:_playerItem];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}


- (void)setupWithURL:(NSURL *)videoURL {
    if (videoURL == nil || videoURL.absoluteString.length <= 0) {
        return ;
    }
    
    self.isPlayComplete = NO;
    self.isPrerolling = NO;
    self.isSeeking = NO;
    
    self.videoURL = videoURL;
    [self removePlayCallback];
    [self removeFirstFrameCallback];
    
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

    if (self.player == nil) {
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        
        [self.player addObserver:self
                      forKeyPath:@"rate"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:NULL];
    }
    if (self.player.currentItem != self.playerItem) {
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    }
    AVPlayerLayer * playerLayer = (AVPlayerLayer *)self.layer;
    playerLayer.videoGravity = [self playerLayerGravityWithScalingMode:self.scalingMode];
    playerLayer.player = self.player;
    
    if (self.controlView && [self.controlView respondsToSelector:@selector(videoPlayerDidSetupWithURL:)]) {
        [self.controlView videoPlayerDidSetupWithURL:self.videoURL];
    }
}

- (void)play {
    if (self.isPlayComplete){
        self.isPlayComplete = NO;
        [self.player seekToTime:kCMTimeZero];
    }
    
    [self.player play];
}

- (void)pause {
    [_player pause];
    self.isPrerolling = NO;
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
    }
    
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.duration = 0;
    self.playableDuration = 0;
    self.isPlayComplete = NO;
    self.isSeeking = NO;
    self.isPrerolling = NO;
    self.seekingTime = 0.f;
    self.callbackInterval = kCMTimeZero;
    
    [self removePlayCallback];
    [self removeFirstFrameCallback];
    
}

- (BOOL)isPlaying {
    if (!isFloatZero(_player.rate)) {
        return YES;
    } else {
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
                
                if (self.shouldAutoplay) {
                    [self.player play];
                }
                
                [self setupPlayCallback];
                [self setupFirstFrameCallback];
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(readyToPlayForVideoPlayer:)]) {
                    [self.delegate readyToPlayForVideoPlayer:self];
                }

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
                    self.playableDuration = playableDuration;
                }
            }
        } else {
            self.playableDuration = 0;
        }
        
        [self callLoadStateChange];
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        if (self.playerItem.isPlaybackBufferEmpty) {
            self.isPrerolling = YES;
        }
        
        [self callLoadStateChange];
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        [self callLoadStateChange];
    } else if ([keyPath isEqualToString:@"playbackBufferFull"]) {
        [self callLoadStateChange];
    } else if ([keyPath isEqualToString:@"rate"]) {
        if (self.player != nil && !isFloatZero(self.player.rate))
            self.isPrerolling = NO;
        
        [self callPlaybackStateChange];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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

#pragma mark - Private Funs

- (void)setupFirstFrameCallback {

    __weak OTVideoPlayerView * weakSelf = self;
    [weakSelf removeFirstFrameCallback];
    
    self.timerObserver = [self.player addBoundaryTimeObserverForTimes:@[[NSValue valueWithCMTime:CMTimeMake(1, 30)]] queue:dispatch_get_main_queue() usingBlock:^{
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(firstVideoFrameDidShowForVideoPlayer:)]) {
            [weakSelf.delegate firstVideoFrameDidShowForVideoPlayer:weakSelf];
        }
        
        [weakSelf removeFirstFrameCallback];
    }];
}

- (void)removeFirstFrameCallback {
    if (self.player == nil) {
        return ;
    }
    
    [self.player removeTimeObserver:self.timerObserver];
    self.timerObserver = nil;
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

- (void)addNotificationForPlayerItem:(AVPlayerItem *)playerItem {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
}

- (void)removeNotificationForPlayerItem:(AVPlayerItem *)playerItem {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
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

#pragma mark - Notification

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
    
    if (_player != nil && !isFloatZero(_player.rate)) {
        return OTVideoLoadStatePlayable | OTVideoLoadStatePlaythroughOK;
    } else if ([playerItem isPlaybackBufferFull]) {
        return OTVideoLoadStatePlayable | OTVideoLoadStatePlaythroughOK;
    } else if ([playerItem isPlaybackLikelyToKeepUp]) {
        return OTVideoLoadStatePlayable | OTVideoLoadStatePlaythroughOK;
    } else if ([playerItem isPlaybackBufferEmpty]) {
        return OTVideoLoadStateStalled;
    } else {
        return OTVideoLoadStateUnknown;
    }
}

- (NSTimeInterval)currentPlaybackTime {
    if (!_player)
        return 0.0f;
    
    if (_isSeeking)
        return _seekingTime;
    
    return CMTimeGetSeconds([_player currentTime]);
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)aCurrentPlaybackTime {
    if (!self.player)
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

- (void)setControlView:(UIView *)controlView {
    [_controlView removeFromSuperview];
    _controlView = controlView;
    
    _controlView.frame = self.bounds;
    _controlView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self addSubview:_controlView];
    
//    if (_delegate && [_delegate respondsToSelector:@selector(didAddToPlayerView:)]) {
//        [_delegate didAddToPlayerView:self];
//    }
}

@end
