#import "AppDelegate.h"
#include "include/cef_browser.h"
#include "include/cef_command_line.h"
#include "include/views/cef_browser_view.h"
#include "include/views/cef_window.h"
#include "include/views/cef_view.h"
#include "include/wrapper/cef_helpers.h"

#include "include/cef_app.h"
#include "include/cef_browser.h"
#include "include/cef_command_line.h"
#include "include/cef_client.h"
#include "tests/cefsimple/simple_handler.h"
#include "ClientApp.h"
#import <AppKit/AppKit.h>

@interface AppDelegate()
@property (strong, nonatomic) NSWindow *window;
@property (strong, nonatomic) NSTimer *cefTimer;
@end

@implementation AppDelegate
@synthesize window = _window;
@synthesize cefTimer = _cefTimer;

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    CefRefPtr<ClientApp> app(new ClientApp);
    
    CefMainArgs main_args;
    CefSettings settings;
    settings.external_message_pump = true;
    
    CefInitialize(main_args, settings, app.get(), NULL);
    
    CefRefPtr<CefCommandLine> command_line =
    CefCommandLine::GetGlobalCommandLine();

    CefBrowserSettings browser_settings;
    
    std::string url;
    

    url = command_line->GetSwitchValue("url");
    if (url.empty()) {
        url = "https://www.google.com";
    }
    

    CefWindowInfo windowInfo;
    CefBrowserSettings browserSettings;
    windowInfo.runtime_style = CEF_RUNTIME_STYLE_ALLOY;
    
    NSView *contentView = self.window.contentView;
    CefRect rect(0, 0, contentView.frame.size.width, contentView.frame.size.height);
    // 设置为子窗口，使 CEF 的浏览器嵌入到 contentView 中
    windowInfo.SetAsChild((__bridge void *)contentView, rect);
    CefBrowserHost::CreateBrowser(windowInfo, nullptr, url, browserSettings, nullptr, nullptr);
//
    // 使用 NSTimer 周期性地调用 CefDoMessageLoopWork，集成到 Cocoa 的主事件循环中
    self.cefTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                     target:self
                                                   selector:@selector(cefDoMessageLoopWork:)
                                                   userInfo:nil
                                                    repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.cefTimer forMode:NSRunLoopCommonModes];
}

// 定时器回调方法：驱动 CEF 的消息循环
- (void)cefDoMessageLoopWork:(NSTimer *)timer {
    CefDoMessageLoopWork();
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    // 停止计时器
    [self.cefTimer invalidate];
    self.cefTimer = nil;
    // 在应用退出前关闭 CEF
    CefShutdown();
}
@end
