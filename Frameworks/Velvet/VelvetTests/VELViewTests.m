//
//  VELViewTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 08.12.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "VELViewTests.h"
#import <Cocoa/Cocoa.h>
#import <Velvet/Velvet.h>

@interface TestView : VELView
@property (nonatomic, assign) BOOL willMoveToSuperviewInvoked;
@property (nonatomic, assign) BOOL willMoveToWindowInvoked;
@property (nonatomic, assign) BOOL didMoveFromSuperviewInvoked;
@property (nonatomic, assign) BOOL didMoveFromWindowInvoked;
@property (nonatomic, unsafe_unretained) VELView *oldSuperview;
@property (nonatomic, unsafe_unretained) VELView *nextSuperview;
@property (nonatomic, unsafe_unretained) VELWindow *oldWindow;
@property (nonatomic, unsafe_unretained) VELWindow *nextWindow;

- (void)reset;
@end

@interface VELViewTests ()
@property (nonatomic, strong, readonly) VELWindow *window;

- (VELWindow *)newWindow;
@end

@implementation VELViewTests
@synthesize window = m_window;

- (void)setUp {
    m_window = [self newWindow];
}

- (VELWindow *)newWindow {
    return [[VELWindow alloc]
        initWithContentRect:CGRectMake(100, 100, 500, 500)
        styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
        backing:NSBackingStoreBuffered
        defer:NO
        screen:nil
    ];
}

- (void)testSizeThatFits {
    VELView *view = [[VELView alloc] init];
    STAssertNotNil(view, @"");

    VELView *subview = [[VELView alloc] initWithFrame:CGRectMake(100, 0, 300, 200)];
    STAssertNotNil(subview, @"");

    [view addSubview:subview];
    [view centeredSizeToFit];

    STAssertEqualsWithAccuracy(view.bounds.size.width, (CGFloat)400, 0.001, @"");
    STAssertEqualsWithAccuracy(view.bounds.size.height, (CGFloat)200, 0.001, @"");
}

- (void)testRemoveFromSuperview {
    VELView *view = [[VELView alloc] init];
    VELView *subview = [[VELView alloc] init];

    [view addSubview:subview];
    STAssertEqualObjects([subview superview], view, @"");
    STAssertEqualObjects([[view subviews] lastObject], subview, @"");

    [subview removeFromSuperview];
    STAssertNil([subview superview], @"");
    STAssertEquals([[view subviews] count], (NSUInteger)0, @"");
}

- (void)testSetSubviews {
    VELView *view = [[VELView alloc] init];

    NSMutableArray *subviews = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0;i < 4;++i) {
        [subviews addObject:[[VELView alloc] init]];
    }

    // make sure that -setSubviews: does not throw an exception
    // (such as mutation while enumerating)
    STAssertNoThrow(view.subviews = subviews, @"");

    // the two arrays should have the same objects, but should not be the same
    // array instance
    STAssertFalse(view.subviews == subviews, @"");
    STAssertEqualObjects(view.subviews, subviews, @"");

    // removing the last subview should remove the last object from the subviews
    // array
    [[subviews lastObject] removeFromSuperview];
    [subviews removeLastObject];

    STAssertEqualObjects(view.subviews, subviews, @"");

    [subviews removeLastObject];

    // calling -setSubviews: with a new array should replace the old one
    view.subviews = subviews;
    STAssertEqualObjects(view.subviews, subviews, @"");
}

- (void)testSubclassInitialization {
    TestView *view = [[TestView alloc] init];
    STAssertNotNil(view, @"");
}

- (void)testMovingToSuperview {
    VELView *superview = [[VELView alloc] init];
    TestView *testView = [[TestView alloc] init];

    testView.nextSuperview = superview;

    [superview addSubview:testView];

    STAssertTrue(testView.willMoveToSuperviewInvoked, @"");
    STAssertTrue(testView.didMoveFromSuperviewInvoked, @"");
    STAssertFalse(testView.willMoveToWindowInvoked, @"");
    STAssertFalse(testView.didMoveFromWindowInvoked, @"");
}

- (void)testMovingAcrossSuperviews {
    TestView *testView = [[TestView alloc] init];

    VELView *firstSuperview = [[VELView alloc] init];
    testView.nextSuperview = firstSuperview;
    [firstSuperview addSubview:testView];

    VELView *secondSuperview = [[VELView alloc] init];

    // reset everything for the crossing over test
    [testView reset];

    testView.oldSuperview = firstSuperview;
    testView.nextSuperview = secondSuperview;

    [secondSuperview addSubview:testView];

    STAssertTrue(testView.willMoveToSuperviewInvoked, @"");
    STAssertTrue(testView.didMoveFromSuperviewInvoked, @"");
    STAssertFalse(testView.willMoveToWindowInvoked, @"");
    STAssertFalse(testView.didMoveFromWindowInvoked, @"");
}

- (void)testMovingAcrossWindows {
    TestView *testView = [[TestView alloc] init];
    VELWindow *firstWindow = [self newWindow];
    VELWindow *secondWindow = [self newWindow];

    testView.nextWindow = firstWindow;
    testView.nextSuperview = firstWindow.rootView;

    [firstWindow.rootView addSubview:testView];

    // reset everything for the crossing over test
    [testView reset];

    testView.oldWindow = firstWindow;
    testView.oldSuperview = firstWindow.rootView;
    testView.nextWindow = secondWindow;
    testView.nextSuperview = secondWindow.rootView;

    [secondWindow.rootView addSubview:testView];

    STAssertTrue(testView.willMoveToWindowInvoked, @"");
    STAssertTrue(testView.didMoveFromWindowInvoked, @"");
    STAssertTrue(testView.willMoveToWindowInvoked, @"");
    STAssertTrue(testView.didMoveFromWindowInvoked, @"");
}

- (void)testMovingToWindowViaSuperview {
    TestView *testView = [[TestView alloc] init];

    testView.nextSuperview = self.window.rootView;
    testView.nextWindow = self.window;

    [self.window.rootView addSubview:testView];

    STAssertTrue(testView.willMoveToSuperviewInvoked, @"");
    STAssertTrue(testView.didMoveFromSuperviewInvoked, @"");
    STAssertTrue(testView.willMoveToWindowInvoked, @"");
    STAssertTrue(testView.didMoveFromWindowInvoked, @"");
}

- (void)testMovingToWindowAsRootView {
    TestView *testView = [[TestView alloc] init];

    testView.nextWindow = self.window;

    [(id)self.window.contentView setRootView:testView];

    STAssertFalse(testView.willMoveToSuperviewInvoked, @"");
    STAssertFalse(testView.didMoveFromSuperviewInvoked, @"");
    STAssertTrue(testView.willMoveToWindowInvoked, @"");
    STAssertTrue(testView.didMoveFromWindowInvoked, @"");
}

@end

@implementation TestView
@synthesize willMoveToSuperviewInvoked;
@synthesize willMoveToWindowInvoked;
@synthesize didMoveFromSuperviewInvoked;
@synthesize didMoveFromWindowInvoked;
@synthesize oldSuperview = m_oldSuperview;
@synthesize oldWindow = m_oldWindow;
@synthesize nextSuperview;
@synthesize nextWindow;

- (void)willMoveToSuperview:(VELView *)superview {
    [super willMoveToSuperview:superview];

    NSAssert(self.superview != superview, @"");
    NSAssert(self.superview == self.oldSuperview, @"");
    NSAssert(superview == self.nextSuperview, @"");

    NSAssert(!self.willMoveToSuperviewInvoked, @"");
    NSAssert(!self.didMoveFromSuperviewInvoked, @"");

    self.willMoveToSuperviewInvoked = YES;
}

- (void)didMoveFromSuperview:(VELView *)oldSuperview {
    [super didMoveFromSuperview:oldSuperview];

    NSAssert(self.superview != oldSuperview, @"");
    NSAssert(self.superview == self.nextSuperview, @"");
    NSAssert(oldSuperview == self.oldSuperview, @"");

    NSAssert(self.willMoveToSuperviewInvoked, @"");
    NSAssert(!self.didMoveFromSuperviewInvoked, @"");

    self.didMoveFromSuperviewInvoked = YES;
}

- (void)willMoveToWindow:(NSWindow *)window {
    [super willMoveToWindow:window];

    NSAssert(self.window != window, @"");
    NSAssert(self.window == self.oldWindow, @"");
    NSAssert(window == self.nextWindow, @"");

    NSAssert(!self.willMoveToWindowInvoked, @"");
    NSAssert(!self.didMoveFromWindowInvoked, @"");

    self.willMoveToWindowInvoked = YES;
}

- (void)didMoveFromWindow:(NSWindow *)oldWindow {
    [super didMoveFromWindow:oldWindow];

    NSAssert(self.window != oldWindow, @"");
    NSAssert(self.window == self.nextWindow, @"");
    NSAssert(oldWindow == self.oldWindow, @"");

    NSAssert(self.willMoveToWindowInvoked, @"");
    NSAssert(!self.didMoveFromWindowInvoked, @"");

    self.didMoveFromWindowInvoked = YES;
}

- (void)reset; {
    self.willMoveToSuperviewInvoked = NO;
    self.willMoveToWindowInvoked = NO;
    self.didMoveFromSuperviewInvoked = NO;
    self.didMoveFromWindowInvoked = NO;
    self.oldSuperview = nil;
    self.oldWindow = nil;
    self.nextSuperview = nil;
    self.nextWindow = nil;
}

@end