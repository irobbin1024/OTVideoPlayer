//
//  INColor.m
//  Bussiness_framework
//
//  Created by Eli Tsai on 5/15/15.
//  Copyright (c) 2015 jiuyan. All rights reserved.
//

#import "UIColor+INColor.h"

@implementation UIColor(INColor)

+ (UIColor*)hex:(NSInteger)hex alpha:(CGFloat)alpha
{
    return [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0
                           green:((float)((hex & 0xFF00) >> 8))/255.0
                            blue:((float)(hex & 0xFF))/255.0 alpha:alpha];
    
    
}

+ (UIColor*)hexString:(NSString *)hexString alpha:(CGFloat)alpha{
    if ([hexString isKindOfClass:[NSString class]]) {
        if ([hexString hasPrefix:@"#"]) {
            NSString *newHexStr = [hexString stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@"0x"];
            int number = (int)strtol([newHexStr cStringUsingEncoding:NSUTF8StringEncoding], NULL, 0);
            return [self hex:number alpha:alpha];
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}


@end
