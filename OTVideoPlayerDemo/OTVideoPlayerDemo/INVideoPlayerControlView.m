//  INVideoPlayerControlView.m
//  INVideoDemo
//
//  Created by baiyang on 2017/3/20.
//  Copyright © 2017年 Hangzhou Jiuyan Technology Co., Ltd. All rights reserved.
//

#import "INVideoPlayerControlView.h"
#import "UIView+Extension.h"
#import "UIColor+INColor.h"

#define kHalfWidth self.frame.size.width * 0.5
#define kHalfHeight self.frame.size.height * 0.5

@interface INVideoPlayerControlView ()

@property (nonatomic, strong) UIView * bottomView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, strong) UIButton * playButton;
@property (nonatomic, strong) UIButton * closeButton;
@property (nonatomic, strong) UISlider * mpVolumeSlider;
@property (nonatomic, strong) UILabel * leftTimeLabel;
@property (nonatomic, strong) UILabel * rightTimeLabel;
@property (nonatomic, strong) UISlider * progressSlider;
@property (nonatomic, strong) UIButton * guideButton;
@property (nonatomic, strong) UIProgressView * volumeProgress;
@property (nonatomic, strong) UIProgressView * loadingProgress;
@property (nonatomic, strong) UITapGestureRecognizer * singleTapGesture;
@property (nonatomic, strong) UITapGestureRecognizer * doubleTapGesture;

@property (nonatomic, assign) BOOL lastStateWhenBackground;
@property (nonatomic, assign) BOOL isPlayDone;
@property (nonatomic, assign) CMTime lastPlayTimeWhenBackground;

@property (nonatomic, assign) BOOL isDragingSlider;
@property (nonatomic, assign) BOOL playDoneDidCallback;

@property (nonatomic, copy) NSString * guideTitle;


// 统计时长

/*
startTime			时间记录的起点
playTimeDuration	时间总长度

done 	开始播放		设置起点
done	播放完成		添加时长
done	停止播放		发送埋点 + 重置时长 + 重置起点

done	暂停播放 		添加时长
done	开始播放 		重设起点

done 	退到后台		如果正在播放，那么 发送埋点 + 添加时长，否则 发送埋点
done	回到前台		重设起点

done	放开进度		添加时长 + 重设起点
*/
@property (nonatomic, strong) NSDate * startTime;
@property (nonatomic, assign) NSTimeInterval playTimeDuration;



@end

@implementation INVideoPlayerControlView

@synthesize playerView;

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
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
        [self.playButton setImage:INVideoImageWithName(@"video_play_big") forState:UIControlStateNormal];
        [self.playButton setImage:INVideoImageWithName(@"video_pause_big") forState:UIControlStateSelected];
        [self.playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.playButton sizeToFit];
        self.playButton.center = CGPointMake(self.width * 0.5, self.height * 0.5);
        self.playButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.playButton.alpha = 0.0;
        
        self.playButton;
    })];
    
    // 关闭
    [self addSubview:({
        self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.closeButton setImage:INVideoImageWithName(@"video_close") forState:UIControlStateNormal];
        [self.closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.closeButton sizeToFit];
        self.closeButton.left = 20;
        self.closeButton.top = 20;
        self.closeButton.alpha = 0.0;
        
        self.closeButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        self.closeButton;
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
        [self.progressSlider setThumbImage:INVideoImageWithName(@"video_progress_dot")  forState:UIControlStateNormal];
        
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
    
    [self addSubview:({
        UIButton * guideButton = [UIButton new];
        guideButton.backgroundColor = [UIColor hex:0x000000 alpha:0.15];
        guideButton.layer.borderColor = [UIColor hex:0xffffff alpha:0.5].CGColor;
        guideButton.layer.borderWidth = 0.5;
        guideButton.layer.cornerRadius = 32/2.0;
        guideButton.layer.masksToBounds = YES;
        guideButton.hidden = YES;
        //    [guideButton setTitle:title forState:UIControlStateNormal];
//        guideButton.titleLabel.font = [UIFont localization65FontOfSize:14.0];
        [guideButton addTarget:self action:@selector(guideButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        guideButton.alpha = 0.0;
        
        [self addSubview:guideButton];
        self.guideButton = guideButton;
        
        self.guideButton;
    })];
    
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
- (void)setDelegate:(id<INVideoPlayerControlViewDelegate>)delegate {
    _delegate = delegate;
    if (_delegate == nil) {
        NSLog(@"delegate nil");
    } else {
        NSLog(@"delegate has value");
    }
}

- (void)singleTapGestureAction:(UITapGestureRecognizer *)sender {
    //    CGPoint location = [sender locationInView:self];
    //    // 时间栏上面部分
    //    if (location.y <= self.height - 40 || self.isSmallMode) {
    //
    //        if (self.isSmallMode == NO || self.canClickPauseOnSmall) {
    //            [self playButtonAction:nil];
    //        }
    //
    //        if (self.delegate && [self.delegate respondsToSelector:@selector(singleTapGestureForControlView:)]) {
    //            [self.delegate singleTapGestureForControlView:self];
    //        }
    //
    //    } else {
    //        [self controlToShow];
    //        [self performSelector:@selector(controlToHide) withObject:nil afterDelay:2];
    //    }
    
    // 控件显示 且 当前为播放状态
    if (self.playButton.alpha >= 0.99 && [self.playerView isPlaying]) {
        [self controlToHide];
    } else {
        [self controlToShow];
        [self performSelector:@selector(controlToHide) withObject:nil afterDelay:2];
    }
    
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(singleTapGestureForControlView:)]) {
        [self.delegate singleTapGestureForControlView:self];
    }
}

- (void)doubleTapGestureAction:(UITapGestureRecognizer *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(doubleTapGestureForControlView:)]) {
        [self.delegate doubleTapGestureForControlView:self];
    }
}

- (void)playButtonAction:(UIButton *)sender {
    if (sender.selected) {
        [self controlToPause];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(pauseButtonActionForControlView:)]) {
            [self.delegate pauseButtonActionForControlView:self];
        }
    } else {
        [self controlToPlay];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(playButtonActionForControlView:)]) {
            [self.delegate playButtonActionForControlView:self];
        }
    }
    
    sender.selected = !sender.selected;
}

- (void)controlToPlay {

    [self resetStartTime];
    
    if (self.isPlayDone) {
        [self.playerView setCurrentPlaybackTime:0.];
    }
    
    
    [self.playerView play];
    
    if (self.isSmallMode) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.playButton.alpha = 0.0;
            self.guideButton.alpha = 0.0;
        });
    }
}
- (void)controlToPause {
    [self.playerView pause];
    
    [self addDate];
}

- (void)closeButtonAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(closeButtonActionForControlView:)]) {
        [self.delegate closeButtonActionForControlView:self];
    }
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
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(progressDidDragActionForControlView:)]) {
        [self.delegate progressDidDragActionForControlView:self];
    }
}

- (void)guideButtonAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didClickGuide:url:)]) {
        [self.delegate didClickGuide:self url:self.guideURL];
    }
}

#pragma mark - INVideoPlayerDelegate

- (void)setupWithURL:(NSURL *)url {
    self.playerView.callbackInterval = CMTimeMake(1, 100);
    [self resetSelf];
}

- (void)readyToPlayForVideoPlayer:(OTVideoPlayerView *)videoPlayer {
    self.leftTimeLabel.text = [self convertTime:[self.playerView currentPlaybackTime]];
    self.rightTimeLabel.text = [self convertTime:[self.playerView duration]];
}
- (void)playbackStateDidChangeForVideoPlayer:(OTVideoPlayerView *)videoPlayer {
    
}
- (void)loadStateDidChangeForVideoPlayer:(OTVideoPlayerView *)videoPlayer {
    switch (videoPlayer.loadState) {
        case OTVideoLoadStateStalled:
        case OTVideoLoadStateUnknown:
            [self.loadingView startAnimating];
            [self callLoadingViewNeedLoading:YES];
            break;
        case OTVideoLoadStatePlaythroughOK:
        case OTVideoLoadStatePlayable:
            [self.loadingView stopAnimating];
            [self callLoadingViewNeedLoading:NO];
            break;
            
        default:
            break;
    }
    
    [self.loadingProgress setProgress:videoPlayer.playableDuration / videoPlayer.duration];
    
}
- (void)videoPlayer:(OTVideoPlayerView *)videoPlayer errorOccur:(NSError *)error {
    [self controlToPause];
    NSLog(@"播放出现问题 %@", error);
}
- (void)playReachToEndForVideoPlayer:(OTVideoPlayerView *)videoPlayer {
    self.isPlayDone = YES;
    
    [self.playButton setSelected:NO];
    [self callPlayButtonStatusChange:YES];
    [self addDate];
    self.startTime = nil;
    videoPlayer.currentPlaybackTime = 0.f;
    
}
- (void)playCallbackForVideoPlayer:(OTVideoPlayerView *)videoPlayer {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (self.isDragingSlider == NO) {
            [self.progressSlider setValue:[self.playerView playableDuration] / 1.0 / self.playerView.duration animated:YES];
        }
        NSString * leftTimeLabelText = [self convertTime:[self.playerView duration]];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.leftTimeLabel.text = leftTimeLabelText;
            [self callCurrentTimeDidChange:[self.playerView playableDuration]];
        });
        
    });
}

- (void)firstVideoFrameDidShowForVideoPlayer:(OTVideoPlayerView *)videoPlayer {
    
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

//- (void)setIsSmallMode:(BOOL)isSmallMode {
//    _isSmallMode = isSmallMode;
//
//    if ([self isForceShowVideoTimeView] == NO) {
//        self.bottomView.alpha = _isSmallMode ? 0.0 : 1.0;
//    } else {
//        self.bottomView.alpha = 1.0;
//    }
//    if (_isSmallMode && self.playerView.playStatus & JYVideoPlayStatusUserPlay) {
//        self.playButton.alpha = 0.0;
//        self.guideButton.alpha = 0.0;
//    } else {
//        self.guideButton.alpha = 1.0;
//    }
//
//    self.closeButton.alpha = _isSmallMode ? 0.0 : 1.0;
//
//    NSLog(@"set small mode %@", _isSmallMode ? @"YES" : @"NO");
//
//    [self.playerView invalidVolumeSetup];
//}

- (BOOL)isForceShowVideoTimeView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(forceShowVideoTimeForControlView:)]) {
        return [self.delegate forceShowVideoTimeForControlView:self];
    }
    return NO;
}

- (void)setThirdpartDelegate:(id<INVideoPlayerControlViewThirdpardDelegate>)thirdpartDelegate {
    _thirdpartDelegate = thirdpartDelegate;
    
    [self callDidGetTotalVideoLength:self.playerView.duration];
    [self callPlayButtonStatusChange:self.playButton.selected];
}

- (NSString *)videoID {
    if (_videoID == nil) {
        return @"";
    }
    return _videoID;
}

- (NSString *)videoFrom {
    if (_videoFrom == nil) {
        return @"";
    }
    return _videoFrom;
}

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

- (void)setGuideButtonShow:(BOOL)show {
    if (self.guideTitle.length > 0 && self.guideURL) {
        self.guideButton.hidden = !show;
    } else {
        self.guideButton.hidden = YES;
    }
    
}

- (void)setupGuideWithTitle:(NSString *)title url:(NSURL *)url {
    self.guideTitle = title;
    self.guideURL = url;
    
    if (title == nil) {
        self.guideButton.hidden = YES;
        return ;
    } else {
        if (self.isSmallMode == NO) {
            self.guideButton.hidden = NO;
        }
    }
    
    [self.guideButton setTitle:[NSString stringWithFormat:@"    %@    ", title] forState:UIControlStateNormal];
    [self.guideButton sizeToFit];
    
    self.guideButton.height = 32;
    self.guideButton.bottom = self.height - 90;
    self.guideButton.centerX = self.width * 0.5;
    self.guideButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
}

//- (void)show4GTipIfNeed {
//    static BOOL isNeedShowVideoNotWifiGuide = YES;
//    if ([self.playerView.videoURL.absoluteString hasPrefix:@"http"]) {
//        NetworkStatus netStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
//        if (netStatus != NotReachable && netStatus != ReachableViaWiFi && isNeedShowVideoNotWifiGuide) {
//            [self makeToast:@"当前为移动网络，注意流量哦~" duration:2. position:@"center"];
//            isNeedShowVideoNotWifiGuide = NO;
//        }
//    }
//}

- (void)letVolumeProgressDismiss {
    [UIView animateWithDuration:0.2 animations:^{
        self.volumeProgress.alpha = 0.0;
    }];
}

- (void)controlToShow {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(controlToHide) object:nil];
    
    [UIView animateWithDuration:0.15 animations:^{
        if (self.isSmallMode == NO) {
            // 只有全屏才会显示控件
            self.closeButton.alpha = 1.0;
            self.bottomView.alpha = 1.0;
            self.playButton.alpha = 1.0;
            self.guideButton.alpha = 1.0;
        }
        
        if ([self isForceShowVideoTimeView]) {
            self.bottomView.alpha = 1.0;
            self.playButton.alpha = 1.0;
            self.guideButton.alpha = 1.0;
        }
    }];
}

- (void)controlToHide {
    [self controlToHide:nil];
}

- (void)controlToHide:(void(^)(void))complete {

    
    [UIView animateWithDuration:0.3 animations:^{
        
        if ([self.playerView isPlaying]) {
            self.playButton.alpha = 0.0;
            self.guideButton.alpha = 0.0;
        }
        
        if ([self isForceShowVideoTimeView]) {
            self.bottomView.alpha = 1.0;
        } else {
            self.bottomView.alpha = 0.0;
        }
        
    } completion:^(BOOL finished) {
        if (complete) {
            complete();
        }
    }];
}

- (void)removeDoubleTap {
    [self removeGestureRecognizer:self.doubleTapGesture];
}

- (void)addDoubleTap {
    // 添加手势
    [self addGestureRecognizer:({
        if (self.doubleTapGesture == nil) {
            self.doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGestureAction:)];
        }
        self.doubleTapGesture.delaysTouchesBegan = YES;
        self.doubleTapGesture.numberOfTapsRequired = 2;
        self.doubleTapGesture.numberOfTouchesRequired = 1;
        
        [self.singleTapGesture requireGestureRecognizerToFail:self.doubleTapGesture];
        
        self.doubleTapGesture;
    })];
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
    [self setupGuideWithTitle:nil url:nil];
    self.leftTimeLabel.text = @"--:--";
    self.rightTimeLabel.text = @"--:--";
    self.canClickPauseOnSmall = NO;
    self.isSmallMode = YES;
    self.delegate = nil;
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

#pragma mark - Thridpart

- (void)callLoadingViewNeedLoading:(BOOL)needLoading {
    if (self.thirdpartDelegate && [self.thirdpartDelegate respondsToSelector:@selector(loadingViewNeedLoading:)]) {
        [self.thirdpartDelegate loadingViewNeedLoading:needLoading];
    }
}

- (void)callPlayButtonStatusChange:(BOOL)status {
    if (self.thirdpartDelegate && [self.thirdpartDelegate respondsToSelector:@selector(playButtonStatusChange:)]) {
        [self.thirdpartDelegate playButtonStatusChange:status];
    }
}

- (void)callLoadingProgressDidChange:(CGFloat)loadingProgress {
    if (self.thirdpartDelegate && [self.thirdpartDelegate respondsToSelector:@selector(loadingProgressDidChange:)]) {
        [self.thirdpartDelegate loadingProgressDidChange:loadingProgress];
    }
}

- (void)callPlayProgressDidChange:(CGFloat)second {
    if (self.thirdpartDelegate && [self.thirdpartDelegate respondsToSelector:@selector(playProgressDidChange:)]) {
        [self.thirdpartDelegate playProgressDidChange:second];
    }
}

- (void)callDidGetTotalVideoLength:(CGFloat)second {
    if (self.thirdpartDelegate && [self.thirdpartDelegate respondsToSelector:@selector(didGetTotalVideoLength:)]) {
        [self.thirdpartDelegate didGetTotalVideoLength:second];
    }
}

- (void)callCurrentTimeDidChange:(CGFloat)second {
    if (self.thirdpartDelegate && [self.thirdpartDelegate respondsToSelector:@selector(currentTimeDidChange:)]) {
        [self.thirdpartDelegate currentTimeDidChange:second];
    }
}

@end
