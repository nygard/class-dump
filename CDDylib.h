#import <Foundation/NSObject.h>

#include <mach-o/loader.h>

@interface CDDylib : NSObject
{
    const struct dylib *dylib;
    NSString *name;
}

- (id)initWithPointer:(const void *)ptr loadCommandBytes:(const void *)lcBytes;
- (void)dealloc;

- (NSString *)name;
- (unsigned long)timestamp;
- (unsigned long)currentVersion;
- (unsigned long)compatibilityVersion;

@end
