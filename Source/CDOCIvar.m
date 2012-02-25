// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDOCIvar.h"

#import "CDClassDump.h"
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"
#import "CDTypeController.h"
#import "CDType.h"

@interface CDOCIvar ()
@property (assign) BOOL hasParsedType; // Private
@end

#pragma mark -

@implementation CDOCIvar
{
    NSString *name;
    NSString *type;
    NSUInteger offset;
    
    BOOL hasParsedType;
    CDType *parsedType;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType offset:(NSUInteger)anOffset;
{
    if ((self = [super init])) {
        name = [aName retain];
        type = [aType retain];
        offset = anOffset;
        
        hasParsedType = NO;
        parsedType = nil;
    }

    return self;
}

- (void)dealloc;
{
    [name release];
    [type release];

    [parsedType release];

    [super dealloc];
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, type: '%@', offset: %lu",
            NSStringFromClass([self class]), self.name, self.type, self.offset];
}

#pragma mark -

@synthesize name;
@synthesize type;
@synthesize offset;
@synthesize hasParsedType;

- (CDType *)parsedType;
{
    if (self.hasParsedType == NO) {
        NSError *error = nil;

        CDTypeParser *parser = [[CDTypeParser alloc] initWithType:type];
        parsedType = [[parser parseType:&error] retain];
        if (parsedType == nil)
            NSLog(@"Warning: Parsing ivar type failed, %@", name);
        [parser release];

        self.hasParsedType = YES;
    }

    return parsedType;
}

- (void)appendToString:(NSMutableString *)resultString typeController:(CDTypeController *)typeController symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    NSString *formattedString = [[typeController ivarTypeFormatter] formatVariable:name type:type symbolReferences:symbolReferences];
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
