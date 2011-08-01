// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "NSData-CDExtensions.h"

#include <openssl/sha.h>

@implementation NSData (CDExtensions)

- (NSString *)hexString;
{
    NSMutableString *str = [NSMutableString string];
    const uint8_t *ptr = [self bytes];
    for (NSUInteger index = 0; index < [self length]; index++) {
        [str appendFormat:@"%02x", *ptr++];
    }
    
    return str;
}

#if 0
// Need to link with Security.framework on Lion for this:
- (NSString *)SHA1DigestString;
{
    NSString *str = nil;
    CFErrorRef error = nil;
    SecTransformRef t1 = SecDigestTransformCreate(kSecDigestSHA1, 0, &error);
    if (t1 == NULL) {
        NSLog(@"Failed to create SHA1 transform, error: %@", error);
    } else {
        error = nil;
        Boolean flag = SecTransformSetAttribute(t1, kSecTransformInputAttributeName, self, &error);
        if (!flag) NSLog(@"set attribute error: %@", error);
        
        error = nil;
        NSData *result = SecTransformExecute(t1, &error);
        if (error != nil) NSLog(@"execute error: %@", error);
        str = [result hexString];
        CFRelease(t1);
    }
    
    //NSLog(@"result is %@", str);
    
    return str;
}
#endif
- (NSString *)SHA1DigestString;
{
    unsigned char digest[SHA_DIGEST_LENGTH];
    unsigned int index;

    //NSLog(@"Calculating SHA1 of %u bytes", [self length]);
    SHA1((unsigned char *)[self bytes], [self length], digest);

    //NSLog(@"SHA_DIGEST_LENGTH: %u", SHA_DIGEST_LENGTH);
    NSMutableString *str = [NSMutableString string];
    for (index = 0; index < SHA_DIGEST_LENGTH; index++)
        [str appendFormat:@"%02x", digest[index]];

    //NSLog(@"result is %@", str);

    return str;
}
@end
