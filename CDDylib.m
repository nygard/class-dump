#import "CDDylib.h"

#import <Foundation/Foundation.h>

// Does this work with different endianness?
static NSString *CDDylibVersionString(unsigned long version)
{
    return [NSString stringWithFormat:@"%d.%d.%d", version >> 16, (version >> 8) & 0xff, version & 0xff];
}

@implementation CDDylib

- (id)initWithPointer:(const void *)ptr loadCommandBytes:(const void *)lcBytes;
{
    const char *str;

    if ([super init] == nil)
        return nil;

    dylib = ptr;
    str = lcBytes + dylib->name.offset;
    //NSLog(@"name offset: %d (%s)", dylib->name.offset, lcBytes + dylib->name.offset);
    name = [[NSString alloc] initWithBytes:str length:strlen(str) encoding:NSASCIIStringEncoding];

    return self;
}

- (void)dealloc;
{
    [name release];
    [super dealloc];
}

- (NSString *)name;
{
    return name;
}

- (unsigned long)timestamp;
{
    return dylib->timestamp;
}

- (unsigned long)currentVersion;
{
    return dylib->current_version;
}

- (unsigned long)compatibilityVersion;
{
    return dylib->compatibility_version;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@ (compatibility version %@, current version %@, timestamp %d [%@])",
                     [self name], CDDylibVersionString([self compatibilityVersion]), CDDylibVersionString([self currentVersion]),
                     [self timestamp], [NSDate dateWithTimeIntervalSince1970:[self timestamp]]];
}

@end
