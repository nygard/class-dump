//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "NSString-Extensions.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/NSString-Extensions.m,v 1.7 2004/01/06 02:31:45 nygard Exp $");

@implementation NSString (CDExtensions)

- (id)initWithCString:(const char *)bytes maximumLength:(unsigned int)maximumLength;
{
    char *buf;

    buf = alloca(maximumLength + 1);
    if (buf == NULL) {
        [self release];
        return nil;
    }

    strncpy(buf, bytes, maximumLength);
    buf[maximumLength] = 0;

    return [self initWithCString:buf];
}

+ (NSString *)spacesIndentedToLevel:(int)level;
{
    return [self spacesIndentedToLevel:level spacesPerLevel:4];
}

+ (NSString *)spacesIndentedToLevel:(int)level spacesPerLevel:(int)spacesPerLevel;
{
    NSString *spaces = @"                                        ";
    NSString *levelSpaces;
    NSMutableString *str;
    int l;

    assert(spacesPerLevel <= [spaces length]);
    levelSpaces = [spaces substringToIndex:spacesPerLevel];

    str = [NSMutableString string];
    for (l = 0; l < level; l++)
        [str appendString:levelSpaces];

    return str;
}

+ (NSString *)stringWithUnichar:(unichar)character;
{
    return [NSString stringWithCharacters:&character length:1];
}

@end
