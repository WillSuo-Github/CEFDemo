#import "AppDelegate.h"
#include "include/cef_app.h"
#include "include/cef_browser.h"
#include "include/cef_command_line.h"
#include "include/cef_client.h"
#include "include/cef_version.h"
#include "ClientApp.h"

#import <AppKit/AppKit.h>

// 用来作为浏览器的 "client"。这里只是一个简单示例。
class SimpleCefClient : public CefClient {
public:
    SimpleCefClient() {}
    // 可根据需要自定义各种 Handler。
    IMPLEMENT_REFCOUNTING(SimpleCefClient);
};

@interface AppDelegate()
@property (strong, nonatomic) NSWindow *window;
@property (strong, nonatomic) NSTimer *cefTimer;  // 用于定时调用 CefDoMessageLoopWork
@end

@implementation AppDelegate
@synthesize window = _window;
@synthesize cefTimer = _cefTimer;

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // 创建 Cef 的 ClientApp 实例
    CefRefPtr<ClientApp> app(new ClientApp);

    CefMainArgs main_args;
    CefSettings settings;
    // 设置使用外部消息泵，这样就不必调用阻塞式的 CefRunMessageLoop
    settings.external_message_pump = true;
    
    CefInitialize(main_args, settings, app.get(), NULL);

    // 准备创建浏览器窗口
    CefWindowInfo windowInfo;
    CefBrowserSettings browserSettings;
    
    // 从命令行中获取 URL（如果有传递 "url" 参数）
    std::string url;
    CefRefPtr<CefCommandLine> command_line = CefCommandLine::GetGlobalCommandLine();
    if (command_line->HasSwitch("url")) {
        url = command_line->GetSwitchValue("url");
    }
    if (url.empty()) {
        // 默认打开 Google 首页
        url = "https://www.google.com";
    }
    
    // 获取当前 NSWindow 的 contentView
    NSView *contentView = self.window.contentView;
    CefRect rect(0, 0, contentView.frame.size.width, contentView.frame.size.height);
    // 设置为子窗口，使 CEF 的浏览器嵌入到 contentView 中
    windowInfo.SetAsChild((__bridge void *)contentView, rect);
    
    // 创建浏览器（这里没有设置自定义的 CefClient，如果需要可以传入 SimpleCefClient）
    CefBrowserHost::CreateBrowser(windowInfo, nullptr, url, browserSettings, nullptr, nullptr);

    // 使用 NSTimer 周期性地调用 CefDoMessageLoopWork，集成到 Cocoa 的主事件循环中
    self.cefTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                     target:self
                                                   selector:@selector(cefDoMessageLoopWork:)
                                                   userInfo:nil
                                                    repeats:YES];
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
