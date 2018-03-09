//
//  DemoVidePlayerControlView.m
//  OTVideoPlayerDemo
//
//  Created by irobbin on 2018/2/27.
//  Copyright © 2018年 irobbin.com. All rights reserved.
//

#import "DemoVidePlayerControlView.h"
#import "UIView+Extension.h"
#import "UIColor+INColor.h"

#define kHalfWidth self.frame.size.width * 0.5
#define kHalfHeight self.frame.size.height * 0.5

@interface DemoVidePlayerControlView()

@property (nonatomic, strong) UIView * bottomView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, strong) UIButton * playButton;
@property (nonatomic, strong) UISlider * mpVolumeSlider;
@property (nonatomic, strong) UILabel * leftTimeLabel;
@property (nonatomic, strong) UILabel * rightTimeLabel;
@property (nonatomic, strong) UISlider * progressSlider;
@property (nonatomic, strong) UIProgressView * volumeProgress;
@property (nonatomic, strong) UIProgressView * loadingProgress;
@property (nonatomic, strong) UITapGestureRecognizer * singleTapGesture;

@property (nonatomic, assign) BOOL lastStateWhenBackground;
@property (nonatomic, assign) BOOL isPlayDone;
@property (nonatomic, assign) CMTime lastPlayTimeWhenBackground;

@property (nonatomic, assign) BOOL isDragingSlider;
@property (nonatomic, assign) BOOL playDoneDidCallback;

@property (nonatomic, strong) NSDate * startTime;
@property (nonatomic, assign) NSTimeInterval playTimeDuration;

@end

@implementation DemoVidePlayerControlView

@synthesize playerView;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews {
    // 菊花
    [self addSubview:({
        self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.loadingView.hidesWhenStopped = YES;
        self.loadingView.center = CGPointMake(self.width * 0.5, self.height * 0.5 - 50);
        self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        self.loadingView;
    })];
    
    // 播放
    [self addSubview:({
        self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.playButton setImage:DemoVideoImageWithName(@"video_play_big") forState:UIControlStateNormal];
        [self.playButton setImage:DemoVideoImageWithName(@"video_pause_big") forState:UIControlStateSelected];
        [self.playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.playButton sizeToFit];
        self.playButton.center = CGPointMake(self.width * 0.5, self.height * 0.5);
        self.playButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.playButton.alpha = 0.0;
        
        self.playButton;
    })];
    
    // 底部栏
    [self addSubview:({
        self.bottomView = [[UIView alloc]initWithFrame:CGRectMake(0, self.height - 40, self.width, 40)];
        self.bottomView.backgroundColor = [UIColor blackColor];
        self.bottomView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        self.bottomView.alpha = 1.0;
        
        self.bottomView;
    })];
    
    // 加载进度
    [self.bottomView addSubview:({
        self.loadingProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        self.loadingProgress.progressTintColor = [UIColor whiteColor];
        self.loadingProgress.trackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
        [self.loadingProgress setProgress:0.0 animated:NO];
        
        self.loadingProgress.width = self.bottomView.width - 120 - 5;
        self.loadingProgress.left = 60 + 5;
        self.loadingProgress.centerY = self.bottomView.height * 0.5;
        
        self.loadingProgress.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        self.loadingProgress;
    })];
    
    // 播放进度条
    [self.bottomView addSubview:({
        self.progressSlider = [[UISlider alloc]init];
        self.progressSlider.backgroundColor = [UIColor clearColor];
        self.progressSlider.value = 0.0;
        self.progressSlider.minimumValue = 0.0;
        self.progressSlider.maximumValue = 1.0;
        self.progressSlider.minimumTrackTintColor = [UIColor hex:0xff4545 alpha:1.0];
        self.progressSlider.maximumTrackTintColor = [UIColor clearColor];
        [self.progressSlider setThumbImage:DemoVideoImageWithName(@"video_progress_dot")  forState:UIControlStateNormal];
        
        [self.progressSlider sizeToFit];
        self.progressSlider.width = self.bottomView.width - 120;
        self.progressSlider.left = 60;
        self.progressSlider.centerY = self.bottomView.height * 0.5;
        self.progressSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        // 进度条的拖拽事件
        [self.progressSlider addTarget:self action:@selector(dragProgressSlideAction:)  forControlEvents:UIControlEventValueChanged];
        // 释放进度条事件
        [self.progressSlider addTarget:self action:@selector(releaseProgressSlideAction:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
        
        self.progressSlider;
    })];
    
    // 左边的时间
    [self.bottomView addSubview:({
        self.leftTimeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 60, self.bottomView.height)];
        self.leftTimeLabel.textAlignment = NSTextAlignmentCenter;
        self.leftTimeLabel.textColor = [UIColor whiteColor];
        self.leftTimeLabel.backgroundColor = [UIColor clearColor];
        self.leftTimeLabel.font = [UIFont systemFontOfSize:12];
        self.leftTimeLabel.text = @"--:--";
        self.leftTimeLabel;
    })];
    
    // 右边的时间
    [self.bottomView addSubview:({
        self.rightTimeLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.bottomView.width - 60, 0, 60, self.bottomView.height)];
        self.rightTimeLabel.textAlignment = NSTextAlignmentCenter;
        self.rightTimeLabel.textColor = [UIColor whiteColor];
        self.rightTimeLabel.backgroundColor = [UIColor clearColor];
        self.rightTimeLabel.font = [UIFont systemFontOfSize:12];
        self.rightTimeLabel.text = @"--:--";
        self.rightTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        self.rightTimeLabel;
    })];
    
    // 添加手势
    [self addGestureRecognizer:({
        self.singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureAction:)];
        self.singleTapGesture.numberOfTapsRequired = 1;
        self.singleTapGesture.numberOfTouchesRequired = 1;
        self.singleTapGesture;
    })];
    
    // 音量进度
    [self addSubview:({
        self.volumeProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        self.volumeProgress.progressTintColor = [UIColor whiteColor];
        self.volumeProgress.trackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
        self.volumeProgress.alpha = 0.0;
        [self.volumeProgress setProgress:0.0 animated:NO];
        
        self.volumeProgress.width = self.width - 30;
        self.volumeProgress.left = 15;
        self.volumeProgress.top = 8;
        
        self.volumeProgress.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        
        self.volumeProgress;
    })];
    
    [self controlToShow];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.progressSlider.width = self.bottomView.width - 120;
    self.progressSlider.left = 60;
    self.progressSlider.centerY = self.bottomView.height * 0.5;
    
    self.loadingProgress.width = self.bottomView.width - 120 - 5;
    self.loadingProgress.left = 60 + 5;
    self.loadingProgress.centerY = self.bottomView.height * 0.5;
}


#pragma mark - Action

- (void)singleTapGestureAction:(UITapGestureRecognizer *)sender {
    
    
    // 控件显示 且 当前为播放状态
    if (self.playButton.alpha >= 0.99 && [self.playerView isPlaying]) {
        [self controlToHide];
    } else {
        [self controlToShow];
        [self performSelector:@selector(controlToHide) withObject:nil afterDelay:2];
    }
}

- (void)playButtonAction:(UIButton *)sender {
    if (sender.selected) {
        [self controlToPause];
    } else {
        [self controlToPlay];
    }
    
//    sender.selected = !sender.selected;
}

- (void)controlToPlay {
    
    [self resetStartTime];
    
    if (self.isPlayDone) {
        [self.playerView setCurrentPlaybackTime:0.];
    }
    
    
    [self.playerView play];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.playButton.alpha = 0.0;
    });
}
- (void)controlToPause {
    [self.playerView pause];
    
    [self addDate];
}

- (void)dragProgressSlideAction:(id)sender {
    self.isDragingSlider = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(controlToHide) object:nil];
}

- (void)releaseProgressSlideAction:(id)sender {
    
    [self addDate];
    [self resetStartTime];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isDragingSlider = NO;
    });
    
    [self.playerView setCurrentPlaybackTime:self.playerView.duration * self.progressSlider.value];
    
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(controlToHide) object:nil];
    [self performSelector:@selector(controlToHide) withObject:nil afterDelay:2.0];
    
}

#pragma mark - INVideoPlayerDelegate

- (void)videoPlayerDidSetupWithURL:(NSURL *)url {
    self.playerView.callbackInterval = CMTimeMake(1, 100);
    [self resetSelf];
}

- (void)readyToPlayForVideoPlayer:(OTVideoPlayerView *)videoPlayer {
    self.leftTimeLabel.text = [self convertTime:[self.playerView currentPlaybackTime]];
    self.rightTimeLabel.text = [self convertTime:[self.playerView duration]];
}
- (void)playbackStateDidChangeForVideoPlayer:(OTVideoPlayerView *)videoPlayer {
    switch (videoPlayer.playbackState) {
        case OTVideoPlaybackStatePaused:
            self.playButton.selected = NO;
//            [self controlToShow];
            break;
        case OTVideoPlaybackStatePlaying:
            self.playButton.selected = YES;
            [self controlToHide];
            break;
        case OTVideoPlaybackStateSeeking:

            break;
        case OTVideoPlaybackStateStopped:
            self.playButton.selected = NO;
            self.progressSlider.value = 0.0;
            
            break;
            
        default:
            break;
    }
}
- (void)loadStateDidChangeForVideoPlayer:(OTVideoPlayerView *)videoPlayer {
    switch (videoPlayer.loadState) {
        case OTVideoLoadStateStalled:
        case OTVideoLoadStateUnknown:
            [self.loadingView startAnimating];
            break;
        case OTVideoLoadStatePlaythroughOK:
        case OTVideoLoadStatePlayable:
            [self.loadingView stopAnimating];
            break;
            
        default:
            break;
    }
    
    [self.loadingProgress setProgress:videoPlayer.playableDuration / videoPlayer.duration];
    
    NSLog(@"loadingProgress %lf", self.loadingProgress.progress);
    
}
- (void)videoPlayer:(OTVideoPlayerView *)videoPlayer errorOccur:(NSError *)error {
    [self controlToPause];
    NSLog(@"播放出现问题 %@", error);
}
- (void)playReachToEndForVideoPlayer:(OTVideoPlayerView *)videoPlayer {
    self.isPlayDone = YES;
    
    [self.playButton setSelected:NO];
    [self addDate];
    self.startTime = nil;
    videoPlayer.currentPlaybackTime = 0.f;
    
}
- (void)playCallbackForVideoPlayer:(OTVideoPlayerView *)videoPlayer {
    NSString * leftTimeLabelText = [self convertTime:[self.playerView currentPlaybackTime]];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isDragingSlider == NO) {
            [self.progressSlider setValue:[self.playerView currentPlaybackTime] / self.playerView.duration animated:YES];
        }
        self.leftTimeLabel.text = leftTimeLabelText;
    });
}

- (void)firstVideoFrameDidShowForVideoPlayer:(OTVideoPlayerView *)videoPlayer {
    NSLog(@"show time %@", [NSDate date]);
}


// ============================== 音量调节相关 =================================
//- (BOOL)needHackVolumeChangeForPlayerView:(JYVideoPlayerView *)playerView {
//    return self.isSmallMode ? NO : YES;
//}
//
//- (void)volumeChanged:(CGFloat)volume playerView:(JYVideoPlayerView *)playerView {
//    [UIView animateWithDuration:0.2 animations:^{
//        self.volumeProgress.alpha = 1.0;
//    }];
//
//    [self.volumeProgress setProgress:volume animated:YES];
//
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(letVolumeProgressDismiss) object:nil];
//    [self performSelector:@selector(letVolumeProgressDismiss) withObject:nil afterDelay:2.];
//}
//
//- (void)didStartPlayVideo:(JYVideoPlayerView *)playerView {
//    if (self.delegate && [self.delegate respondsToSelector:@selector(videoDidStartPlayForControlView:)]) {
//        [self.delegate videoDidStartPlayForControlView:self];
//    }
//
//    [self resetStartTime];
//}


#pragma mark - Setter & Getter


#pragma mark - Funs

- (void)resetStartTime {
    self.startTime = [NSDate date];
    
    NSLog(@"reset add date duration = %f, start time = %@  \n", self.playTimeDuration, self.startTime);
}

- (void)addDate {
    if (self.startTime == nil) {
        return ;
    }
    NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:self.startTime];
    self.playTimeDuration += time;
    self.startTime = [NSDate date];
    NSLog(@"add add date duration = %f, start time = %@ \n", self.playTimeDuration, self.startTime);
    
}

- (void)letVolumeProgressDismiss {
    [UIView animateWithDuration:0.2 animations:^{
        self.volumeProgress.alpha = 0.0;
    }];
}

- (void)controlToShow {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(controlToHide) object:nil];
    
    [UIView animateWithDuration:0.15 animations:^{
        self.bottomView.alpha = 1.0;
        self.playButton.alpha = 1.0;
    }];
}

- (void)controlToHide {
    [self controlToHide:nil];
}

- (void)controlToHide:(void(^)(void))complete {
    
    
    [UIView animateWithDuration:0.3 animations:^{
        
        if ([self.playerView isPlaying]) {
            self.playButton.alpha = 0.0;
        }
        
        self.bottomView.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        if (complete) {
            complete();
        }
    }];
}

- (NSString *)convertTime:(CGFloat)second{
    NSInteger _hour = second / 3600;
    NSInteger _minute = (second - (_hour * 3600)) / 60;
    NSInteger _second = second - (_hour * 3600) - (_minute * 60);
    
    if (second/3600 >= 1) {
        return [NSString stringWithFormat:@"%.2ld:%.2ld:%.2ld", _hour, _minute, _second];
    } else {
        return [NSString stringWithFormat:@"%.2ld'%.2ld\"", _minute, _second];
    }
}

- (void)resetSelf {
    [self addDate];
    [self sendVideoDurationEvent];
    self.leftTimeLabel.text = @"--:--";
    self.rightTimeLabel.text = @"--:--";
    [self.progressSlider setValue:0.0 animated:YES];
    [self.loadingProgress setProgress:0.0];
}

- (void)sendVideoDurationEvent {
    if (self.playTimeDuration > 0.0) {
        NSLog(@"send date duration = %f, start time = %@ \n", self.playTimeDuration, self.startTime);
        self.playTimeDuration = 0;
        self.startTime = nil;
    }
}

@end
