# OTPlayerCache
<p align="left">
<a href="https://travis-ci.org/irobbin1024/OTVideoPlayer"><img src="https://travis-ci.org/irobbin1024/OTVideoPlayer.svg?branch=master"></a>
<a href="https://img.shields.io/cocoapods/v/OTVideoPlayer.svg"><img src="https://img.shields.io/cocoapods/v/OTVideoPlayer.svg"></a>
<a href="https://img.shields.io/cocoapods/l/OTVideoPlayer.svg"><img src="https://img.shields.io/cocoapods/l/OTVideoPlayer?style=flat"></a>
</p>



一个基于AVPlayer的播放器，只有一个类来做封装，没有太多功能。

OTVideoPlayerView 对单例有原生的支持，如果有这方面需求的集成起来会比较方便

## 安装方法

### 手动安装

> 直接将OTVideoPlayer的文件拖入项目中

### CocoaPods

```
pod 'OTVideoPlayer'
```

## 使用方法
### 1. 自定义一个播放器类
```objective-c
// OTVideoPlayerView 是一个单例
+ (OTVideoPlayerView *)singlePlayerView {
    static OTVideoPlayerView *staticInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        staticInstance = [[OTVideoPlayerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        
        DemoVidePlayerControlView * controlView = [DemoVidePlayerControlView new];
        staticInstance.controlView = controlView;
        staticInstance.controlView.playerView = staticInstance;
        staticInstance.delegate = controlView;
        
    });
    
    return staticInstance;
}

- (void)initSubViews {
    
    self.videoPlayerView = [self.class singlePlayerView];
    [self.videoPlayerView reset];
    
    if (self.videoPlayerView.superview != self) {
        [self.videoPlayerView removeFromSuperview];
        [self addSubview:self.videoPlayerView];
        self.videoPlayerView.frame = self.bounds;
        self.videoPlayerView.translatesAutoresizingMaskIntoConstraints = NO;
    }
}
```
### 2. 初始化并播放
```objective-c
self.playerView = [[DemoVideoPlayerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * (3 / 4.0))];
    self.playerView.center = CGPointMake(self.view.frame.size.width * 0.5, self.view.frame.size.height * 0.5);
    [self.view addSubview:self.playerView];
    
    [self.playerView setupWithURL:[NSURL URLWithString:@"http://aliuwmp3.changba.com/userdata/video/45F6BD5E445E4C029C33DC5901307461.mp4"]];

    [self.playerView play];
```
