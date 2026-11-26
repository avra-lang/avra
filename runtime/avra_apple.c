// An Apple SDK's own calls, answered where the tree holds their C.
#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif
#if defined(__APPLE__) && TARGET_OS_IPHONE
#include <CoreFoundation/CoreFoundation.h>

// A CFString over UTF-8 text; NULL when the text is not UTF-8.
void *avra_apple_cfstring(const char *text) {
    return (void *)CFStringCreateWithCString(NULL, text, kCFStringEncodingUTF8);
}
#endif
