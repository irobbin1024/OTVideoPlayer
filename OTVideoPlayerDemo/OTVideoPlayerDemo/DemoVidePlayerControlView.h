//
//  DemoVidePlayerControlView.h
//  OTVideoPlayerDemo
//
//  Created by irobbin on 2018/2/27.
//  Copyright © 2018年 irobbin.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTVideoPlayerView.h"

#define DemoVideoImageWithName(name) [UIImage imageNamed:[NSString stringWithFormat:@"DemoPlayer.bundle/%@", name]]

@interface DemoVidePlayerControlView : UIView <OTVideoPlayerDelegate, OTVideoPlayerBeControlView>

@end
