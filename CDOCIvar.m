//  This file is part of class-dump, a utility for exmaing the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDOCIvar.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>
#import "CDClassDump.h"
#import "CDTypeFormatter.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDOCIvar.m,v 1.15 2004/01/06 02:18:18 nygard Exp $");

@implementation CDOCIvar

- (id)initWithName:(NSString *)aName type:(NSString *)aType offset:(int)anOffset;
{
    if ([super init] == nil)
        return nil;

    name = [aName retain];
    type = [aType retain];
    offset = anOffset;

    return self;
}

- (void)dealloc;
{
    [name release];
    [type release];

    [super dealloc];
}

- (NSString *)name;
{
    return name;
}

- (NSString *)type;
{
    return type;
}

- (int)offset;
{
    return offset;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, type: '%@', offset: %d",
                     NSStringFromClass([self class]), name, type, offset];
}

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump;
{
    NSString *formattedString;

    formattedString = [[aClassDump ivarTypeFormatter] formatVariable:name type:type];
    if (formattedString != nil) {
        [resultString appendString:formattedString];
        [resultString appendString:@";"];
    } else
        [resultString appendFormat:@"    // Error parsing type: %@, name: %@", type, name];
}

@end
