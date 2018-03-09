//
//  ViewController.m
//  OTVideoPlayerDemo
//
//  Created by irobbin on 2018/2/26.
//  Copyright © 2018年 irobbin.com. All rights reserved.
//

#import "ViewController.h"
#import "DemoVideoPlayerView.h"

@interface ViewController ()

@property (nonatomic, strong) DemoVideoPlayerView * playerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.playerView = [[DemoVideoPlayerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * (3 / 4.0))];
    self.playerView.center = CGPointMake(self.view.frame.size.width * 0.5, self.view.frame.size.height * 0.5);
    [self.view addSubview:self.playerView];
    
    [self.playerView setupWithURL:[NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/gear5/prog_index.m3u8"]];
//    [self.playerView setupWithURL:[NSURL URLWithString:@"http://ali-v4d.xiaoying.tv/20180309/z5d3X8/3z80Xvn819.mp4"]];

    self.playerView.videoPlayerView.shouldAutoplay = YES;
    
    NSLog(@"show time %@", [NSDate date]);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
