//
//  OTVideoPlayerView.m
//  OTVideoPlayerDemo
//
//  Created by irobbin on 2018/2/26.
//  Copyright © 2018年 irobbin.com. All rights reserved.
//

#import "OTVideoPlayerView.h"
@import AVFoundation;

@interface OTVideoPlayerView()

@property (nonatomic, strong) NSURL * videoURL;
@property (nonatomic, strong) AVURLAsset * playAsset;
@property (nonatomic, strong) AVPlayerItem * playerItem;
@property (nonatomic, strong) AVPlayer * player;

@property (nonatomic, assign) BOOL isPlayComplete;


@end

@implementation OTVideoPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (void)dealloc {
    [_player removeObserver:self forKeyPath:@"rate"];
}

- (void)setupWithURL:(NSURL *)videoURL {
    if (videoURL == nil || videoURL.absoluteString.length <= 0) {
        return ;
    }
    
    self.videoURL = videoURL;
    
    self.playAsset = [AVURLAsset URLAssetWithURL:self.videoURL options:nil];
    if (self.playerItem) {
        // remove kvo
    }
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.playAsset];
    // add kvo
    {
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
}

- (void)stop {
    [_player pause];
    self.isPlayComplete = YES;
}

- (void)reset {
    
}

- (BOOL)isPlaying {
    return NO;
}

- (UIImage *)thumbnailImageAtCurrentTime {
    return nil;
}

#pragma mark - Private Funs

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
                                

#pragma mark - Getter & Setter
- (void)setScalingMode:(OTVideoScalingMode)scalingMode {
    _scalingMode = scalingMode;
    AVPlayerLayer * playerLayer = (AVPlayerLayer *)self.layer;
    playerLayer.videoGravity = [self playerLayerGravityWithScalingMode:_scalingMode];
}

@end
