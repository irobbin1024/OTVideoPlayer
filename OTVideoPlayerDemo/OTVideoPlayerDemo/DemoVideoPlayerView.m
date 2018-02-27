//
//  DemoVideoPlayerView.m
//  OTVideoPlayerDemo
//
//  Created by irobbin on 2018/2/27.
//  Copyright © 2018年 irobbin.com. All rights reserved.
//

#import "DemoVideoPlayerView.h"

@interface DemoVideoPlayerView()

@property (nonatomic, strong) UIView * controlView;

@end

@implementation DemoVideoPlayerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews {
    
    self.controlView = [[UIView alloc] initWithFrame:self.bounds];

    [self addSubview:self.controlView];
}

@end
