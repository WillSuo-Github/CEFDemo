#import <Cocoa/Cocoa.h>
// 引入 CEF 头文件 (假设 CEF_ROOT/include 已经在 include path)
#include "include/cef_app.h"
#include "include/cef_browser.h"
#include "include/cef_command_line.h"
#include "include/cef_client.h"
#include "include/cef_version.h"

static bool gCEFInitialized = false;


class MinimalCefApp : public CefApp {
public:
    IMPLEMENT_REFCOUNTING(MinimalCefApp);
};


// 用来作为浏览器的 "client"。先用一个空壳类演示。
class SimpleCefClient : public CefClient {
public:
    SimpleCefClient() {}
    // 在这里可以自定义各种 Handler，先略。
    IMPLEMENT_REFCOUNTING(SimpleCefClient);
};

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong) NSWindow *window;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // 1) 创建并显示你自己的 NSWindow
    NSRect frame = NSMakeRect(100, 100, 800, 600);
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:(NSWindowStyleMaskTitled |
                                                         NSWindowStyleMaskClosable |
                                                         NSWindowStyleMaskResizable)
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    [self.window setTitle:@"CEF + Cocoa Demo"];
    [self.window makeKeyAndOrderFront:nil];

    // 2) 创建 CEF Browser
    CefWindowInfo window_info;
    // 把 NSView* 转为同样的 "window handle"
    window_info.SetAsChild((__bridge void*)[self.window contentView],
                           CefRect(0, 0, 800, 600));
      // 或者使用 SetAsWindowless 之类也可

    CefBrowserSettings browser_settings;
    CefRefPtr<SimpleCefClient> client(new SimpleCefClient());

    // 加载 google
    CefBrowserHost::CreateBrowser(window_info, client.get(),
                                  "https://www.google.com",
                                  browser_settings, nullptr, nullptr);
}
@end

int main(int argc, const char * argv[]) {
    // 1) 在 NSApplicationMain 之前初始化 CEF
    //    或者先启动 Cocoa，再在 AppDelegate 里 init 也行。
    
    // 构造 CEF main args
    CefMainArgs main_args(argc, (char**)argv);

    // (可选) 如果要多进程，需要写一个派生于 CefApp 的类, 并在这里传递
    CefRefPtr<CefApp> cefApp(new MinimalCefApp());

    // 子进程入口。如果返回 >=0 说明是子进程，会直接 exit
    int exit_code = CefExecuteProcess(main_args, cefApp, nullptr);
    if (exit_code >= 0) {
        return exit_code;
    }

    // CEF 初始化设置
    CefSettings settings;
    settings.no_sandbox = true;
    settings.log_severity = LOGSEVERITY_INFO;

    // 初始化 CEF
    CefInitialize(main_args, settings, cefApp, nullptr);
    gCEFInitialized = true;

    // 2) 启动 Cocoa 应用主循环
    //    这里使用 NSApplicationMain，会读取 Info.plist
    int result = NSApplicationMain(argc, argv);

    // 3) 在主循环结束后，关闭 CEF
    if (gCEFInitialized) {
        CefShutdown();
    }

    return result;
}

