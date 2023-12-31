//
//  TRMalleableFrameView.m
//  Discord Classic
//
//  Created by Julian Triveri on 3/11/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//
// yes i inherited these files from that proj (keyboard code is from there too)
//creds: https://github.com/cellomonster/iOS-Discord-Classic
//code for the UITextV
#import "TRMalleableFrameView.h"
@implementation UIView (TRMalleableFrameView)

- (CGFloat) height {
    return self.frame.size.height;
}

- (CGFloat) width {
    return self.frame.size.width;
}

- (CGFloat) x {
    return self.frame.origin.x;
}

- (CGFloat) y {
    return self.frame.origin.y;
}

- (CGFloat) centerY {
    return self.center.y;
}

- (CGFloat) centerX {
    return self.center.x;
}

- (void) setHeight:(CGFloat) newHeight {
    CGRect frame = self.frame;
    frame.size.height = newHeight;
    self.frame = frame;
}

- (void) setWidth:(CGFloat) newWidth {
    CGRect frame = self.frame;
    frame.size.width = newWidth;
    self.frame = frame;
}

- (void) setX:(CGFloat) newX {
    CGRect frame = self.frame;
    frame.origin.x = newX;
    self.frame = frame;
}

- (void) setY:(CGFloat) newY {
    CGRect frame = self.frame;
    frame.origin.y = newY;
    self.frame = frame;
}

@end
