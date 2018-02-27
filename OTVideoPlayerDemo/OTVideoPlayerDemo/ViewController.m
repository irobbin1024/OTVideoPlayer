//
//  ViewController.m
//  OTVideoPlayerDemo
//
//  Created by irobbin on 2018/2/26.
//  Copyright © 2018年 irobbin.com. All rights reserved.
//

#import "ViewController.h"
#import "OTVideoPlayerView.h"
#import "DemoVidePlayerControlView.h"

@interface ViewController ()

@property (nonatomic, strong) OTVideoPlayerView * playerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.playerView = [[OTVideoPlayerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * (2 / 3.0))];
    self.playerView.center = CGPointMake(self.view.frame.size.width * 0.5, self.view.frame.size.height * 0.5);
    [self.view addSubview:self.playerView];
    

    DemoVidePlayerControlView * controlView = [DemoVidePlayerControlView new];
    self.playerView.controlView = controlView;
    self.playerView.controlView.playerView = self.playerView;
    self.playerView.delegate = controlView;
    
    [self.playerView setupWithURL:[NSURL URLWithString:@"http://aliuwmp3.changba.com/userdata/video/45F6BD5E445E4C029C33DC5901307461.mp4"]];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
