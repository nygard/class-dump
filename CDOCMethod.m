//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDOCMethod.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>
#import "CDClassDump.h"
#import "CDTypeFormatter.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDOCMethod.m,v 1.17 2004/01/20 05:00:23 nygard Exp $");

@implementation CDOCMethod

- (id)init;
{
    [NSException raise:@"RejectUnusedImplementation" format:@"-initWithName:type:imp: is the designated initializer"];
    return nil;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType imp:(unsigned long)anImp;
{
    if ([super init] == nil)
        return nil;

    name = [aName retain];
    type = [aType retain];
    imp = anImp;

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

- (unsigned long)imp;
{
    return imp;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, type: %@, imp: 0x%08x",

                     NSStringFromClass([self class]), name, type, imp];
}

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump;
{
    NSString *formattedString;

    formattedString = [[aClassDump methodTypeFormatter] formatMethodName:name type:type];
    //NSLog(@"%s, formattedString: '%@'", _cmd, formattedString);
    if (formattedString != nil) {
        [resultString appendString:formattedString];
        [resultString appendString:@";"];
    } else
        [resultString appendFormat:@"    // Error parsing type: %@, name: %@", type, name];
}

- (NSComparisonResult)ascendingCompareByName:(CDOCMethod *)otherMethod;
{
    return [name compare:[otherMethod name]];
}

@end
