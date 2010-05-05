// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "NSData-CDExtensions.h"

#include <openssl/sha.h>

@implementation NSData (CDExtensions)

- (NSString *)SHA1DigestString;
{
    NSMutableString *str;
    unsigned char digest[SHA_DIGEST_LENGTH];
    unsigned int index;

    //NSLog(@"Calculating SHA1 of %u bytes", [self length]);
    SHA1((unsigned char *)[self bytes], [self length], digest);

    //NSLog(@"SHA_DIGEST_LENGTH: %u", SHA_DIGEST_LENGTH);
    str = [NSMutableString string];
    for (index = 0; index < SHA_DIGEST_LENGTH; index++)
        [str appendFormat:@"%02x", digest[index]];

    //NSLog(@"result is %@", str);

    return str;
}

@end
