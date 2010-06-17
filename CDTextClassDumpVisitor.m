// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDTextClassDumpVisitor.h"

#include <mach-o/arch.h>

#import "NSArray-Extensions.h"
#import "CDClassDump.h"
#import "CDObjectiveC1Processor.h"
#import "CDMachOFile.h"
#import "CDOCProtocol.h"
#import "CDLCDylib.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDSymbolReferences.h"
#import "CDOCMethod.h"
#import "CDOCProperty.h"
#import "CDTypeFormatter.h"
#import "CDTypeController.h"
#import "CDVisitorPropertyState.h"

static BOOL debug = NO;

@implementation CDTextClassDumpVisitor

- (id)init;
{
    if ([super init] == nil)
        return nil;

    resultString = [[NSMutableString alloc] init];
    symbolReferences = [[CDSymbolReferences alloc] init];

    return self;
}

- (void)dealloc;
{
    [resultString release];
    [symbolReferences release];

    [super dealloc];
}

- (void)writeResultToStandardOutput;
{
    NSData *data;

    data = [resultString dataUsingEncoding:NSUTF8StringEncoding];
    [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    NSArray *protocols;

    if ([aClass isExported] == NO)
        [resultString appendString:@"// Not exported\n"];

    [resultString appendFormat:@"@interface %@", [aClass name]];
    if ([aClass superClassName] != nil)
        [resultString appendFormat:@" : %@", [aClass superClassName]];

    protocols = [aClass protocols];
    if ([protocols count] > 0) {
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];
        [symbolReferences addProtocolNamesFromArray:[protocols arrayByMappingSelector:@selector(name)]];
    }

    [resultString appendString:@"\n"];
}

- (void)didVisitClass:(CDOCClass *)aClass;
{
    if ([aClass hasMethods])
        [resultString appendString:@"\n"];

    [resultString appendString:@"@end\n\n"];
}

- (void)willVisitIvarsOfClass:(CDOCClass *)aClass;
{
    [resultString appendString:@"{\n"];
}

- (void)didVisitIvarsOfClass:(CDOCClass *)aClass;
{
    [resultString appendString:@"}\n\n"];
}

- (void)willVisitCategory:(CDOCCategory *)aCategory;
{
    NSArray *protocols;

    [resultString appendFormat:@"@interface %@ (%@)", [aCategory className], [aCategory name]];

    protocols = [aCategory protocols];
    if ([protocols count] > 0) {
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];
        [symbolReferences addProtocolNamesFromArray:[protocols arrayByMappingSelector:@selector(name)]];
    }

    [resultString appendString:@"\n"];
}

- (void)didVisitCategory:(CDOCCategory *)aCategory;
{
    [resultString appendString:@"@end\n\n"];
}

- (void)willVisitProtocol:(CDOCProtocol *)aProtocol;
{
    NSArray *protocols;

    [resultString appendFormat:@"@protocol %@", [aProtocol name]];

    protocols = [aProtocol protocols];
    if ([protocols count] > 0) {
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];
        [symbolReferences addProtocolNamesFromArray:[protocols arrayByMappingSelector:@selector(name)]];
    }

    [resultString appendString:@"\n"];
}

- (void)willVisitOptionalMethods;
{
    [resultString appendString:@"\n@optional\n"];
}

- (void)didVisitProtocol:(CDOCProtocol *)aProtocol;
{
    [resultString appendString:@"@end\n\n"];
}

- (void)visitClassMethod:(CDOCMethod *)aMethod;
{
    [resultString appendString:@"+ "];
    [aMethod appendToString:resultString typeController:[classDump typeController] symbolReferences:symbolReferences];
    [resultString appendString:@"\n"];
}

- (void)visitInstanceMethod:(CDOCMethod *)aMethod propertyState:(CDVisitorPropertyState *)propertyState;
{
    CDOCProperty *property;

    property = [propertyState propertyForAccessor:[aMethod name]];
    if (property == nil) {
        //NSLog(@"No property for method: %@", [aMethod name]);
        [resultString appendString:@"- "];
        [aMethod appendToString:resultString typeController:[classDump typeController] symbolReferences:symbolReferences];
        [resultString appendString:@"\n"];
    } else {
        if ([propertyState hasUsedProperty:property] == NO) {
            //NSLog(@"Emitting property %@ triggered by method %@", [property name], [aMethod name]);
            [self visitProperty:property];
            [propertyState useProperty:property];
        } else {
            //NSLog(@"Have already emitted property %@ triggered by method %@", [property name], [aMethod name]);
        }
    }
}

- (void)visitIvar:(CDOCIvar *)anIvar;
{
    [anIvar appendToString:resultString typeController:[classDump typeController] symbolReferences:symbolReferences];
    [resultString appendString:@"\n"];
}

- (void)_visitProperty:(CDOCProperty *)aProperty parsedType:(CDType *)parsedType attributes:(NSArray *)attrs;
{
    NSMutableArray *alist, *unknownAttrs;
    NSString *backingVar = nil;
    NSString *formattedString;
    BOOL isWeak = NO;
    BOOL isDynamic = NO;

    alist = [[NSMutableArray alloc] init];
    unknownAttrs = [[NSMutableArray alloc] init];

    // objc_v2_encode_prop_attr() in gcc/objc/objc-act.c

    for (NSString *attr in attrs) {
        if ([attr hasPrefix:@"T"]) {
            if (debug) NSLog(@"Warning: Property attribute 'T' should occur only occur at the beginning");
        } else if ([attr hasPrefix:@"R"]) {
            [alist addObject:@"readonly"];
        } else if ([attr hasPrefix:@"C"]) {
            [alist addObject:@"copy"];
        } else if ([attr hasPrefix:@"&"]) {
            [alist addObject:@"retain"];
        } else if ([attr hasPrefix:@"G"]) {
            [alist addObject:[NSString stringWithFormat:@"getter=%@", [attr substringFromIndex:1]]];
        } else if ([attr hasPrefix:@"S"]) {
            [alist addObject:[NSString stringWithFormat:@"setter=%@", [attr substringFromIndex:1]]];
        } else if ([attr hasPrefix:@"V"]) {
            backingVar = [attr substringFromIndex:1];
        } else if ([attr hasPrefix:@"N"]) {
            [alist addObject:@"nonatomic"];
        } else if ([attr hasPrefix:@"W"]) {
            // @property(assign) __weak NSObject *prop;
            // Only appears with GC.
            isWeak = YES;
        } else if ([attr hasPrefix:@"P"]) {
            // @property(assign) __strong NSObject *prop;
            // Only appears with GC.
            // This is the default.
            isWeak = NO;
        } else if ([attr hasPrefix:@"D"]) {
            // Dynamic property.  Implementation supplied at runtime.
            // @property int prop; // @dynamic prop;
            isDynamic = YES;
        } else {
            if (debug) NSLog(@"Warning: Unknown property attribute '%@'", attr);
            [unknownAttrs addObject:attr];
        }
    }

    if ([alist count] > 0) {
        [resultString appendFormat:@"@property(%@) ", [alist componentsJoinedByString:@", "]];
    } else {
        [resultString appendString:@"@property "];
    }

    if (isWeak)
        [resultString appendString:@"__weak "];

    formattedString = [[[classDump typeController] propertyTypeFormatter] formatVariable:[aProperty name] parsedType:parsedType symbolReferences:symbolReferences];
    [resultString appendFormat:@"%@;", formattedString];

    if (isDynamic) {
        [resultString appendFormat:@" // @dynamic %@;", [aProperty name]];
    } else if (backingVar != nil) {
        if ([backingVar isEqualToString:[aProperty name]]) {
            [resultString appendFormat:@" // @synthesize %@;", [aProperty name]];
        } else {
            [resultString appendFormat:@" // @synthesize %@=%@;", [aProperty name], backingVar];
        }
    }

    [resultString appendString:@"\n"];
    if ([unknownAttrs count] > 0) {
        [resultString appendFormat:@"// Preceding property had unknown attributes: %@\n", [unknownAttrs componentsJoinedByString:@","]];
        if ([[aProperty attributeString] length] > 80) {
            [resultString appendFormat:@"// Original attribute string (following type): %@\n\n", [aProperty attributeStringAfterType]];
        } else {
            [resultString appendFormat:@"// Original attribute string: %@\n\n", [aProperty attributeString]];
        }
    }

    [alist release];
    [unknownAttrs release];
}

- (void)visitProperty:(CDOCProperty *)aProperty;
{
    CDType *parsedType;

    parsedType = [aProperty type];
    if (parsedType == nil) {
        if ([[aProperty attributeString] hasPrefix:@"T"]) {
            [resultString appendFormat:@"// Error parsing type for property %@:\n", [aProperty name]];
            [resultString appendFormat:@"// Property attributes: %@\n\n", [aProperty attributeString]];
        } else {
            [resultString appendFormat:@"// Error: Property attributes should begin with the type ('T') attribute, property name: %@\n", [aProperty name]];
            [resultString appendFormat:@"// Property attributes: %@\n\n", [aProperty attributeString]];
        }
    } else {
        [self _visitProperty:aProperty parsedType:parsedType attributes:[aProperty attributes]];
    }
}

#define ADD_SPACE

- (void)didVisitPropertiesOfClass:(CDOCClass *)aClass;
{
#ifdef ADD_SPACE
    if ([[aClass properties] count] > 0)
        [resultString appendString:@"\n"];
#endif
}

- (void)willVisitPropertiesOfCategory:(CDOCCategory *)aCategory;
{
#ifdef ADD_SPACE
    if ([[aCategory properties] count] > 0)
        [resultString appendString:@"\n"];
#endif
}

- (void)didVisitPropertiesOfCategory:(CDOCCategory *)aCategory;
{
#ifdef ADD_SPACE
    if ([[aCategory properties] count] > 0/* && [aCategory hasMethods]*/)
        [resultString appendString:@"\n"];
#endif
}

- (void)willVisitPropertiesOfProtocol:(CDOCProtocol *)aProtocol;
{
#ifdef ADD_SPACE
    if ([[aProtocol properties] count] > 0)
        [resultString appendString:@"\n"];
#endif
}

- (void)didVisitPropertiesOfProtocol:(CDOCProtocol *)aProtocol;
{
#ifdef ADD_SPACE
    if ([[aProtocol properties] count] > 0 /*&& [aProtocol hasMethods]*/)
        [resultString appendString:@"\n"];
#endif
}

- (void)visitRemainingProperties:(CDVisitorPropertyState *)propertyState;
{
    NSArray *remaining = [propertyState remainingProperties];

    if ([remaining count] > 0) {
        [resultString appendString:@"\n"];
        [resultString appendFormat:@"// Remaining properties\n"];
        //NSLog(@"Warning: remaining undeclared property count: %u", [remaining count]);
        //NSLog(@"remaining: %@", remaining);
        for (CDOCProperty *property in remaining)
            [self visitProperty:property];
    }
}

@end
