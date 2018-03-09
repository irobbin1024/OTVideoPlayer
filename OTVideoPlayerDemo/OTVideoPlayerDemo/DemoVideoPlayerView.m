//
//  DemoVideoPlayerView.m
//  OTVideoPlayerDemo
//
//  Created by irobbin on 2018/2/27.
//  Copyright © 2018年 irobbin.com. All rights reserved.
//

#import "DemoVideoPlayerView.h"
#import "OTVideoPlayerView.h"
#import "DemoVidePlayerControlView.h"

@interface DemoVideoPlayerView()



@end

@implementation DemoVideoPlayerView

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

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubViews];
    }
    return self;
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

- (void)setupWithURL:(NSURL *)url {
    [self.videoPlayerView setupWithURL:url];
}

- (void)play {
    [self.videoPlayerView play];
}

@end
