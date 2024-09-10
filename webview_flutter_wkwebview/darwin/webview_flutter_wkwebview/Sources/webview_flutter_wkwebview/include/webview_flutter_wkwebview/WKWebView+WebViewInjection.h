//
//  WKWebView+WebViewInjection.h
//  Pods
//
//  Created by Nhan Nguyen Trong on 29/03/2022.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (WebViewInjection)
+ (void)allowDisplayingKeyboardWithoutUserAction;
@end

NS_ASSUME_NONNULL_END
