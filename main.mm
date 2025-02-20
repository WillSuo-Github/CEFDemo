#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
#import "include/wrapper/cef_library_loader.h"

int main(int argc, const char * argv[]) {
    CefScopedLibraryLoader library_loader;
    if (!library_loader.LoadInMain()) {
      return 1;
    }
    
    [NSApplication sharedApplication];

    AppDelegate *delegate = [[AppDelegate alloc] init];
    [NSApp setDelegate:delegate];

    return NSApplicationMain(argc, argv);
}
