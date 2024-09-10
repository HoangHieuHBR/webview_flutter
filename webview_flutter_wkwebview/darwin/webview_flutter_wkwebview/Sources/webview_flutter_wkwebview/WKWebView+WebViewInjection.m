//
//  WKWebView+WebViewInjection.m
//  Pods
//
//  Created by Nhan Nguyen Trong on 29/03/2022.
//

#import "WKWebView+WebViewInjection.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h> 

@interface _NoInputAccessoryView : NSObject
@end

@implementation _NoInputAccessoryView

- (id)inputAccessoryView {
    return nil;
}

@end

@implementation WKWebView (WebViewInjection)

+ (void)allowDisplayingKeyboardWithoutUserAction {
    Class class = NSClassFromString(@"WKContentView");

    // Define version constants
    NSOperatingSystemVersion iOS_11_3_0 = (NSOperatingSystemVersion){11, 3, 0};
    NSOperatingSystemVersion iOS_12_2_0 = (NSOperatingSystemVersion){12, 2, 0};
    NSOperatingSystemVersion iOS_13_0_0 = (NSOperatingSystemVersion){13, 0, 0};

    // Define the selector based on the iOS version
    SEL selector = [self getSelectorForCurrentiOSVersion];

    if (!selector) {
        NSLog(@"Unsupported iOS version");
        return;
    }

    Method method = class_getInstanceMethod(class, selector);
    if (!method) {
        NSLog(@"Could not find method for selector");
        return;
    }

    IMP original = method_getImplementation(method);
    IMP override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, BOOL arg3, id arg4) {
        ((void (*)(id, SEL, void*, BOOL, BOOL, BOOL, id))original)(me, selector, arg0, TRUE, arg2, arg3, arg4);
    });

    method_setImplementation(method, override);
}

// Helper function to determine selector based on iOS version
+ (SEL)getSelectorForCurrentiOSVersion {
    NSOperatingSystemVersion iOS_11_3_0 = (NSOperatingSystemVersion){11, 3, 0};
    NSOperatingSystemVersion iOS_12_2_0 = (NSOperatingSystemVersion){12, 2, 0};
    NSOperatingSystemVersion iOS_13_0_0 = (NSOperatingSystemVersion){13, 0, 0};

    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:iOS_13_0_0]) {
        return sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:activityStateChanges:userObject:");
    } else if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:iOS_12_2_0]) {
        return sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:changingActivityState:userObject:");
    } else if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:iOS_11_3_0]) {
        return sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:");
    } else {
        return sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:userObject:");
    }
}

+ (void)removeInputAccessoryViewFromWKWebView:(WKWebView *)webView {
    UIView *targetView = [self findTargetViewInScrollView:webView.scrollView];

    if (!targetView) {
        return;
    }

    NSString *noInputAccessoryViewClassName = [NSString stringWithFormat:@"%@_NoInputAccessoryView", targetView.class.superclass];
    Class newClass = NSClassFromString(noInputAccessoryViewClassName);

    if (!newClass) {
        newClass = [self createNewClassForTargetView:targetView className:noInputAccessoryViewClassName];
        if (!newClass) {
            return;
        }
    }

    object_setClass(targetView, newClass);
}

+ (UIView *)findTargetViewInScrollView:(UIScrollView *)scrollView {
    for (UIView *view in scrollView.subviews) {
        if ([[view.class description] hasPrefix:@"WKContent"]) {
            return view;
        }
    }
    return nil;
}

+ (Class)createNewClassForTargetView:(UIView *)targetView className:(NSString *)className {
    Class newClass = objc_allocateClassPair(targetView.class, [className cStringUsingEncoding:NSASCIIStringEncoding], 0);
    if (!newClass) {
        return nil;
    }

    Method method = class_getInstanceMethod([_NoInputAccessoryView class], @selector(inputAccessoryView));
    class_addMethod(newClass, @selector(inputAccessoryView), method_getImplementation(method), method_getTypeEncoding(method));

    objc_registerClassPair(newClass);
    return newClass;
}

@end
