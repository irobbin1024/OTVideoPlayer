//
//  DemoVideoPlayerView.h
//  OTVideoPlayerDemo
//
//  Created by irobbin on 2018/2/27.
//  Copyright © 2018年 irobbin.com. All rights reserved.
//

#import "OTVideoPlayerView.h"

@class OTVideoPlayerView;

@interface DemoVideoPlayerView : UIView

@property (nonatomic, strong) OTVideoPlayerView * videoPlayerView;

- (void)setupWithURL:(NSURL *)url;
- (void)play;

@end
