#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
#include "include/wrapper/cef_library_loader.h"
#include "include/cef_sandbox_mac.h"

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
