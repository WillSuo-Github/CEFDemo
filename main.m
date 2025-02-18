#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong) NSWindow *window;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSRect frame = NSMakeRect(100, 100, 600, 400);
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:(NSWindowStyleMaskTitled
                                                         | NSWindowStyleMaskClosable
                                                         | NSWindowStyleMaskResizable)
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    [self.window setTitle:@"My Empty Window"];
    [self.window makeKeyAndOrderFront:nil];
}
@end

int main(int argc, const char * argv[]) {
    // 创建并运行 NSApplication
    [NSApplication sharedApplication];

    AppDelegate *delegate = [[AppDelegate alloc] init];
    [NSApp setDelegate:delegate];

    return NSApplicationMain(argc, argv);
}