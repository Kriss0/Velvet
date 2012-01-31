//
//  VELViewController.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 21.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "VELViewController.h"
#import "VELHostView.h"
#import "VELView.h"
#import "VELViewPrivate.h"

@interface VELViewController ()
@property (nonatomic, strong, readwrite) VELView *view;

/**
 * Returns the next <VELView> that is an ancestor of <bridgedView> (or
 * <bridgedView> itself). Returns `nil` if no Velvet hierarchies exist at or
 * above the given view.
 *
 * This will also traverse any host views, to find Velvet hierarchies even
 * across bridging boundaries.
 *
 * @param bridgedView The view to return a <VELView> ancestor of. If this view
 * is a <VELView>, it is returned.
 */
- (VELView *)ancestorVELViewOfBridgedView:(id<VELBridgedView>)bridgedView;
@end

@implementation VELViewController

#pragma mark Properties

@synthesize view = m_view;

- (BOOL)isViewLoaded {
    return m_view != nil;
}

- (VELView *)view {
    if (!self.viewLoaded) {
        self.view = [self loadView];
    }

    return m_view;
}

- (void)setView:(VELView *)view {
    if (view == m_view)
        return;

    view.viewController = self;

    if (!m_view) {
        m_view = view;
        return;
    }

    [m_view removeFromSuperview];

    if (!view)
        [self viewWillUnload];

    m_view = view;

    if (!view)
        [self viewDidUnload];
}

- (VELViewController *)parentViewController {
    if (![self isViewLoaded])
        return nil;

    VELView *view = self.view;

    do {
        // traverse superviews until we reach a root view, then keep trying on
        // any Velvet hierarchies above its hostView

        VELView *nextView = view.superview ?: [self ancestorVELViewOfBridgedView:view.hostView];
        if (!nextView)
            break;

        view = nextView;

        if (view.viewController)
            return view.viewController;
    } while (view);

    return nil;
}

#pragma mark Lifecycle

- (VELView *)loadView; {
    return [[VELView alloc] init];
}

- (void)viewDidUnload; {
}

- (void)viewWillUnload; {
}

- (void)dealloc {
    // remove 'self' as the next responder
    if (m_view.nextResponder == self)
        m_view.nextResponder = nil;

    // make sure to always call -viewWillUnload and -viewDidUnload
    self.view = nil;

    [self.undoManager removeAllActionsWithTarget:self];
}

#pragma mark Presentation

- (void)viewWillAppear; {
}

- (void)viewDidAppear; {
}

- (void)viewWillDisappear; {
}

- (void)viewDidDisappear; {
}

#pragma mark Responder chain

- (BOOL)acceptsFirstResponder {
    return YES;
}

#pragma mark View hierarchy

- (VELView *)ancestorVELViewOfBridgedView:(id<VELBridgedView>)bridgedView; {
    if (!bridgedView)
        return nil;

    if ([bridgedView isKindOfClass:[VELView class]])
        return (id)bridgedView;

    // we don't need to check bridgedView.superview, since we already know it's
    // not in a Velvet hierarchy

    id<VELHostView> hostView = bridgedView.hostView;
    if (!hostView)
        return nil;

    return [self ancestorVELViewOfBridgedView:hostView];
}

@end
