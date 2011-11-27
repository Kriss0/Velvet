//
//  VELScrollView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 27.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELScrollView.h>
#import <Velvet/VELNSView.h>
#import <Velvet/VELViewProtected.h>
#import <QuartzCore/QuartzCore.h>

@interface VELScrollView ()
/*
 * The layer which will contain any subviews, responsible for scrolling and
 * clipping them.
 */
@property (nonatomic, strong, readonly) CAScrollLayer *scrollLayer;

/*
 * Contains a horizontal `NSScroller`.
 */
@property (nonatomic, strong, readonly) VELNSView *horizontalScrollerHost;

/*
 * Contains a vertical `NSScroller`.
 */
@property (nonatomic, strong, readonly) VELNSView *verticalScrollerHost;
@end

@implementation VELScrollView

#pragma mark Properties

@synthesize scrollLayer = m_scrollLayer;
@synthesize horizontalScrollerHost = m_horizontalScrollerHost;
@synthesize verticalScrollerHost = m_verticalScrollerHost;

- (NSScroller *)horizontalScroller {
    return (id)self.horizontalScrollerHost.NSView;
}

- (NSScroller *)verticalScroller {
    return (id)self.verticalScrollerHost.NSView;
}

#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    // we don't even provide a setter for these ivars, because they should never
    // change after initialization
    
    m_scrollLayer = [[CAScrollLayer alloc] init];
    m_scrollLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    [self.layer addSublayer:m_scrollLayer];
    self.scrollLayer.contentsRect = CGRectMake(0, 0, 1000, 1000);

    // TODO: subscribe to notifications about preferred scroller style changing?
    NSScrollerStyle style = [NSScroller preferredScrollerStyle];
    CGFloat scrollerWidth = [NSScroller scrollerWidthForControlSize:NSRegularControlSize scrollerStyle:style];

    NSScroller *(^preparedScrollerWithSize)(CGSize) = ^(CGSize size){
        NSScroller *scroller = [[NSScroller alloc] initWithFrame:NSMakeRect(0, 0, size.width, size.height)];
        scroller.scrollerStyle = style;
        scroller.enabled = YES;

        scroller.knobProportion = 0.5;
        scroller.doubleValue = 0;
        return scroller;
    };

    m_horizontalScrollerHost = [[VELNSView alloc] initWithNSView:preparedScrollerWithSize(CGSizeMake(100, scrollerWidth))];
    m_verticalScrollerHost = [[VELNSView alloc] initWithNSView:preparedScrollerWithSize(CGSizeMake(scrollerWidth, 100))];

    self.subviews = [NSArray arrayWithObjects:m_horizontalScrollerHost, m_verticalScrollerHost, nil];

    return self;
}

#pragma mark View hierarchy

- (void)addSubviewToLayer:(VELView *)view; {
    // play nicely with the scrollers -- use the default behavior
    if (view == m_horizontalScrollerHost || view == m_verticalScrollerHost) {
        [super addSubviewToLayer:view];
        return;
    }

    [self.scrollLayer addSublayer:view.layer];
}

#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect bounds = self.bounds;
    CGRect contentRect = self.scrollLayer.contentsRect;

    self.horizontalScrollerHost.frame = CGRectMake(0, 0, bounds.size.width, self.horizontalScrollerHost.bounds.size.height);
    self.horizontalScroller.knobProportion = CGRectGetWidth(bounds) / CGRectGetWidth(contentRect);

    CGFloat verticalScrollerHostWidth = self.verticalScrollerHost.bounds.size.width;
    self.verticalScrollerHost.frame = CGRectMake(bounds.size.width - verticalScrollerHostWidth, 0, verticalScrollerHostWidth, bounds.size.height);
    self.verticalScroller.knobProportion = CGRectGetHeight(bounds) / CGRectGetHeight(contentRect);
}

@end
