//
//  VELViewControllerTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 21.12.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "VELViewControllerTests.h"
#import <Velvet/Velvet.h>
#import <Cocoa/Cocoa.h>

// these are static because these methods are only called from
// -[VELViewController dealloc], and we need to make sure that they were
// called after the view controller has been destroyed
static BOOL testViewControllerWillUnloadCalled = NO;
static BOOL testViewControllerDidUnloadCalled = NO;

@interface TestViewController : VELViewController
@property (nonatomic) BOOL viewWillAppearCalled;
@property (nonatomic) BOOL viewDidAppearCalled;
@property (nonatomic) BOOL viewWillDisappearCalled;
@property (nonatomic) BOOL viewDidDisappearCalled;
@end

@interface VELViewControllerTests () {
    /*
     * A window to hold the <visibleView>.
     */
    VELWindow *m_window;
}

/*
 * A view that is guaranteed to be visible on screen, to be used for
 * testing appearance/disappearance of subviews.
 */
@property (nonatomic, strong, readonly) VELView *visibleView;
@end

@implementation VELViewControllerTests
- (VELView *)visibleView {
    return m_window.rootView;
}

- (void)setUp {
    testViewControllerWillUnloadCalled = NO;
    testViewControllerDidUnloadCalled = NO;

    m_window = [[VELWindow alloc]
        initWithContentRect:CGRectMake(100, 100, 500, 500)
        styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
        backing:NSBackingStoreBuffered
        defer:NO
        screen:nil
    ];

    [m_window makeKeyAndOrderFront:nil];
}

- (void)tearDown {
    [m_window close];
}

- (void)testInitialization {
    VELViewController *controller = [[VELViewController alloc] init];
    STAssertNotNil(controller, @"");
    STAssertFalse(controller.viewLoaded, @"");
}

- (void)testImplicitLoadView {
    VELViewController *controller = [[VELViewController alloc] init];

    // using the 'view' property should load it into memory
    VELView *view = controller.view;

    STAssertNotNil(view, @"");
    STAssertTrue(controller.viewLoaded, @"");

    // re-reading the property should return the same view
    STAssertEqualObjects(controller.view, view, @"");
}

- (void)testLoadView {
    VELViewController *controller = [[VELViewController alloc] init];

    VELView *view = [controller loadView];
    STAssertNotNil(view, @"");

    // the view should have zero width and zero height
    STAssertTrue(CGRectEqualToRect(view.bounds, CGRectZero), @"");
}

- (void)testViewUnloading {
    // instantiate a view controller in an explicit autorelease pool to
    // deterministically control when -dealloc is invoked
    @autoreleasepool {
        __autoreleasing TestViewController *vc = [[TestViewController alloc] init];

        // access the view property so that it gets loaded in the first place
        [vc view];
    }

    STAssertTrue(testViewControllerWillUnloadCalled, @"");
    STAssertTrue(testViewControllerDidUnloadCalled, @"");
}

- (void)testViewAppearance {
    TestViewController *vc = [[TestViewController alloc] init];
    [self.visibleView addSubview:vc.view];

    STAssertTrue(vc.viewWillAppearCalled, @"");
    STAssertTrue(vc.viewDidAppearCalled, @"");
}

- (void)testViewDisappearance {
    TestViewController *vc = [[TestViewController alloc] init];
    [self.visibleView addSubview:vc.view];

    [vc.view removeFromSuperview];
    STAssertTrue(vc.viewWillDisappearCalled, @"");
    STAssertTrue(vc.viewDidDisappearCalled, @"");
}

- (void)testMovingBetweenSuperviews {
    TestViewController *vc = [[TestViewController alloc] init];

    VELView *firstSuperview = [[VELView alloc] init];
    [self.visibleView addSubview:firstSuperview];

    VELView *secondSuperview = [[VELView alloc] init];
    [self.visibleView addSubview:secondSuperview];

    [firstSuperview addSubview:vc.view];

    // clear out the flags before we change its superview
    vc.viewWillAppearCalled = NO;
    vc.viewDidAppearCalled = NO;

    [secondSuperview addSubview:vc.view];

    // moving superviews should not generate new lifecycle messages
    STAssertFalse(vc.viewWillAppearCalled, @"");
    STAssertFalse(vc.viewDidAppearCalled, @"");
    STAssertFalse(vc.viewWillDisappearCalled, @"");
    STAssertFalse(vc.viewDidDisappearCalled, @"");
}

@end

@implementation TestViewController
@synthesize viewWillAppearCalled;
@synthesize viewDidAppearCalled;
@synthesize viewWillDisappearCalled;
@synthesize viewDidDisappearCalled;

- (VELView *)loadView {
    VELView *view = [super loadView];

    NSAssert(!self.viewWillAppearCalled, @"");
    NSAssert(!self.viewDidAppearCalled, @"");
    NSAssert(!self.viewWillDisappearCalled, @"");
    NSAssert(!self.viewDidDisappearCalled, @"");
    NSAssert(!testViewControllerWillUnloadCalled, @"");
    NSAssert(!testViewControllerDidUnloadCalled, @"");

    return view;
}

- (void)viewWillAppear {
    [super viewWillAppear];

    NSAssert(self.viewLoaded, @"");
    NSAssert(!self.viewWillAppearCalled, @"");
    NSAssert(!self.viewDidAppearCalled, @"");
    NSAssert(!self.viewWillDisappearCalled, @"");
    NSAssert(!self.viewDidDisappearCalled, @"");
    NSAssert(!testViewControllerWillUnloadCalled, @"");
    NSAssert(!testViewControllerDidUnloadCalled, @"");

    NSAssert(!self.view.superview, @"");
    NSAssert(!self.view.window, @"");

    self.viewWillAppearCalled = YES;
}

- (void)viewDidAppear {
    [super viewDidAppear];

    NSAssert(self.viewLoaded, @"");
    NSAssert(self.viewWillAppearCalled, @"");
    NSAssert(!self.viewDidAppearCalled, @"");
    NSAssert(!self.viewWillDisappearCalled, @"");
    NSAssert(!self.viewDidDisappearCalled, @"");
    NSAssert(!testViewControllerWillUnloadCalled, @"");
    NSAssert(!testViewControllerDidUnloadCalled, @"");

    NSAssert(self.view.superview, @"");
    NSAssert(self.view.window, @"");

    self.viewDidAppearCalled = YES;
}

- (void)viewWillDisappear {
    [super viewWillDisappear];

    NSAssert(self.viewLoaded, @"");
    NSAssert(self.viewWillAppearCalled, @"");
    NSAssert(self.viewDidAppearCalled, @"");
    NSAssert(!self.viewWillDisappearCalled, @"");
    NSAssert(!self.viewDidDisappearCalled, @"");
    NSAssert(!testViewControllerWillUnloadCalled, @"");
    NSAssert(!testViewControllerDidUnloadCalled, @"");

    NSAssert(self.view.superview, @"");
    NSAssert(self.view.window, @"");

    self.viewWillDisappearCalled = YES;
}

- (void)viewDidDisappear {
    [super viewDidDisappear];

    NSAssert(self.viewLoaded, @"");
    NSAssert(self.viewWillAppearCalled, @"");
    NSAssert(self.viewDidAppearCalled, @"");
    NSAssert(self.viewWillDisappearCalled, @"");
    NSAssert(!self.viewDidDisappearCalled, @"");
    NSAssert(!testViewControllerWillUnloadCalled, @"");
    NSAssert(!testViewControllerDidUnloadCalled, @"");

    NSAssert(!self.view.superview, @"");
    NSAssert(!self.view.window, @"");

    self.viewDidDisappearCalled = YES;
}

- (void)viewWillUnload {
    [super viewWillUnload];

    NSAssert(self.viewLoaded, @"");
    NSAssert(!testViewControllerWillUnloadCalled, @"");
    NSAssert(!testViewControllerDidUnloadCalled, @"");

    NSAssert(!self.view.superview, @"");
    NSAssert(!self.view.window, @"");

    testViewControllerWillUnloadCalled = YES;
}

- (void)viewDidUnload {
    [super viewDidUnload];

    NSAssert(!self.viewLoaded, @"");
    NSAssert(testViewControllerWillUnloadCalled, @"");
    NSAssert(!testViewControllerDidUnloadCalled, @"");

    testViewControllerDidUnloadCalled = YES;
}

@end