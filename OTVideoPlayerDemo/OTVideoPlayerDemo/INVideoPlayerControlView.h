//JYVButton
//  INVideoPlayerControlView.h
//  INVideoDemo
//
//  Created by baiyang on 2017/3/20.
//  Copyright © 2017年 Hangzhou Jiuyan Technology Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTVideoPlayerView.h"

#define INVideoImageWithName(name) [UIImage imageNamed:[NSString stringWithFormat:@"OTPlayer.bundle/%@", name]]

@class INVideoPlayerControlView;

@protocol INVideoPlayerControlViewThirdpardDelegate <NSObject>

- (void)loadingViewNeedLoading:(BOOL)needLoading;
- (void)playButtonStatusChange:(BOOL)status;
- (void)loadingProgressDidChange:(CGFloat)loadingProgress;
- (void)playProgressDidChange:(CGFloat)progress;
- (void)didGetTotalVideoLength:(CGFloat)second;
- (void)currentTimeDidChange:(CGFloat)second;

@end

@protocol INVideoPlayerControlViewDelegate <NSObject>

// 单击
- (void)singleTapGestureForControlView:(INVideoPlayerControlView *)controlView;
// 双击
- (void)doubleTapGestureForControlView:(INVideoPlayerControlView *)controlView;
// 强制显示进度栏
- (BOOL)forceShowVideoTimeForControlView:(INVideoPlayerControlView *)controlView;
// 是否需要双击
- (BOOL)needDoubleTapGestureForControlView:(INVideoPlayerControlView *)controlView;
// 点击关闭
- (void)closeButtonActionForControlView:(INVideoPlayerControlView *)controlView;
// 点击播放
- (void)playButtonActionForControlView:(INVideoPlayerControlView *)controlView;
// 点击暂停
- (void)pauseButtonActionForControlView:(INVideoPlayerControlView *)controlView;
// 拖动了进度条
- (void)progressDidDragActionForControlView:(INVideoPlayerControlView *)controlView;
// 播放完成
- (void)playDoneForControlView:(INVideoPlayerControlView *)controlView;
// 视频开始播放了
- (void)videoDidStartPlayForControlView:(INVideoPlayerControlView *)controlView;
// 播放出错，无法播放
- (void)videoPlayFailure:(NSError *)error controlView:(INVideoPlayerControlView *)controlView;
// 点击了引导按钮
- (void)didClickGuide:(INVideoPlayerControlView *)videoView url:(NSURL *)url;

@end

@interface INVideoPlayerControlView : UIView <OTVideoPlayerDelegate, OTVideoPlayerBeControlView>

@property (nonatomic, assign) BOOL isSmallMode;
@property (nonatomic, assign) BOOL canClickPauseOnSmall; // 小图模式能否暂停
@property (nonatomic, weak) id<INVideoPlayerControlViewDelegate> delegate;
@property (nonatomic, weak) id<INVideoPlayerControlViewThirdpardDelegate> thirdpartDelegate;
@property (nonatomic, strong) NSURL * guideURL;
@property (nonatomic, strong) NSString * videoID;
@property (nonatomic, strong) NSString * videoFrom;

- (void)setupGuideWithTitle:(NSString *)title url:(NSURL *)url;

- (void)controlToPlay;
- (void)controlToPause;

- (void)setGuideButtonShow:(BOOL)show;

@end
