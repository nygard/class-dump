// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDOCIvar.h"

#import "NSError-CDExtensions.h"
#import "CDClassDump.h"
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"
#import "CDTypeController.h"

@implementation CDOCIvar

- (id)initWithName:(NSString *)aName type:(NSString *)aType offset:(NSUInteger)anOffset;
{
    if ([super init] == nil)
        return nil;

    name = [aName retain];
    type = [aType retain];
    offset = anOffset;

    hasParsedType = NO;
    parsedType = nil;

    return self;
}

- (void)dealloc;
{
    [name release];
    [type release];

    [parsedType release];

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

- (NSUInteger)offset;
{
    return offset;
}

- (CDType *)parsedType;
{
    if (hasParsedType == NO) {
        CDTypeParser *parser;
        NSError *error;

        parser = [[CDTypeParser alloc] initWithType:type];
        parsedType = [[parser parseType:&error] retain];
        if (parsedType == nil)
            NSLog(@"Warning: Parsing ivar type failed, %@", name);
        [parser release];

        hasParsedType = YES;
    }

    return parsedType;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, type: '%@', offset: %lu",
                     NSStringFromClass([self class]), name, type, offset];
}

- (void)appendToString:(NSMutableString *)resultString typeController:(CDTypeController *)typeController symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    NSString *formattedString;

    formattedString = [[typeController ivarTypeFormatter] formatVariable:name type:type symbolReferences:symbolReferences];
    if (formattedString != nil) {
        [resultString appendString:formattedString];
        [resultString appendString:@";"];
        if ([typeController shouldShowIvarOffsets]) {
            [resultString appendFormat:@"\t// %1$d = 0x%1$x", offset];
        }
    } else
        [resultString appendFormat:@"    // Error parsing type: %@, name: %@", type, name];
}

@end
