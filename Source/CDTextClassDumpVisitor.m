// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDTextClassDumpVisitor.h"

#import "CDClassDump.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDSymbolReferences.h"
#import "CDOCMethod.h"
#import "CDOCProperty.h"
#import "CDTypeController.h"
#import "CDTypeFormatter.h"
#import "CDVisitorPropertyState.h"
#import "CDOCIvar.h"

// Add newlines after properties
#define ADD_SPACE

static BOOL debug = NO;

@interface CDTextClassDumpVisitor ()
- (void)_visitProperty:(CDOCProperty *)property parsedType:(CDType *)parsedType attributes:(NSArray *)attrs;
@end

#pragma mark -

@implementation CDTextClassDumpVisitor
{
    NSMutableString *resultString;
    CDSymbolReferences *symbolReferences;
}

- (id)init;
{
    if ((self = [super init])) {
        resultString = [[NSMutableString alloc] init];
        symbolReferences = [[CDSymbolReferences alloc] init];
    }

    return self;
}

#pragma mark -

- (void)willVisitClass:(CDOCClass *)aClass;
{
    if (aClass.isExported == NO)
        [resultString appendString:@"// Not exported\n"];

    [resultString appendFormat:@"@interface %@", aClass.name];
    if (aClass.superClassName != nil)
        [resultString appendFormat:@" : %@", aClass.superClassName];

    NSArray *protocols = aClass.protocols;
    if ([protocols count] > 0) {
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];
        [symbolReferences addProtocolNamesFromArray:[protocols arrayByMappingSelector:@selector(name)]];
    }

    [resultString appendString:@"\n"];
}

- (void)didVisitClass:(CDOCClass *)aClass;
{
    if (aClass.hasMethods)
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

- (void)willVisitCategory:(CDOCCategory *)category;
{
    [resultString appendFormat:@"@interface %@ (%@)", category.className, category.name];

    NSArray *protocols = category.protocols;
    if ([protocols count] > 0) {
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];
        [symbolReferences addProtocolNamesFromArray:[protocols arrayByMappingSelector:@selector(name)]];
    }

    [resultString appendString:@"\n"];
}

- (void)didVisitCategory:(CDOCCategory *)category;
{
    [resultString appendString:@"@end\n\n"];
}

- (void)willVisitProtocol:(CDOCProtocol *)protocol;
{
    [resultString appendFormat:@"@protocol %@", protocol.name];

    NSArray *protocols = protocol.protocols;
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

- (void)didVisitProtocol:(CDOCProtocol *)protocol;
{
    [resultString appendString:@"@end\n\n"];
}

- (void)visitClassMethod:(CDOCMethod *)method;
{
    [resultString appendString:@"+ "];
    [method appendToString:resultString typeController:self.classDump.typeController symbolReferences:symbolReferences];
    [resultString appendString:@"\n"];
}

- (void)visitInstanceMethod:(CDOCMethod *)method propertyState:(CDVisitorPropertyState *)propertyState;
{
    CDOCProperty *property = [propertyState propertyForAccessor:method.name];
    if (property == nil) {
        //NSLog(@"No property for method: %@", method.name);
        [resultString appendString:@"- "];
        [method appendToString:resultString typeController:self.classDump.typeController symbolReferences:symbolReferences];
        [resultString appendString:@"\n"];
    } else {
        if ([propertyState hasUsedProperty:property] == NO) {
            //NSLog(@"Emitting property %@ triggered by method %@", property.name, method.name);
            [self visitProperty:property];
            [propertyState useProperty:property];
        } else {
            //NSLog(@"Have already emitted property %@ triggered by method %@", property.name, method.name);
        }
    }
}

- (void)visitIvar:(CDOCIvar *)ivar;
{
    [ivar appendToString:resultString typeController:self.classDump.typeController symbolReferences:symbolReferences];
    [resultString appendString:@"\n"];
}

- (void)visitProperty:(CDOCProperty *)property;
{
    CDType *parsedType = property.type;
    if (parsedType == nil) {
        if ([property.attributeString hasPrefix:@"T"]) {
            [resultString appendFormat:@"// Error parsing type for property %@:\n", property.name];
            [resultString appendFormat:@"// Property attributes: %@\n\n", property.attributeString];
        } else {
            [resultString appendFormat:@"// Error: Property attributes should begin with the type ('T') attribute, property name: %@\n", property.name];
            [resultString appendFormat:@"// Property attributes: %@\n\n", property.attributeString];
        }
    } else {
        [self _visitProperty:property parsedType:parsedType attributes:property.attributes];
    }
}

- (void)didVisitPropertiesOfClass:(CDOCClass *)aClass;
{
#ifdef ADD_SPACE
    if ([aClass.properties count] > 0)
        [resultString appendString:@"\n"];
#endif
}

- (void)willVisitPropertiesOfCategory:(CDOCCategory *)category;
{
#ifdef ADD_SPACE
    if ([category.properties count] > 0)
        [resultString appendString:@"\n"];
#endif
}

- (void)didVisitPropertiesOfCategory:(CDOCCategory *)category;
{
#ifdef ADD_SPACE
    if ([category.properties count] > 0/* && [aCategory hasMethods]*/)
        [resultString appendString:@"\n"];
#endif
}

- (void)willVisitPropertiesOfProtocol:(CDOCProtocol *)protocol;
{
#ifdef ADD_SPACE
    if ([protocol.properties count] > 0)
        [resultString appendString:@"\n"];
#endif
}

- (void)didVisitPropertiesOfProtocol:(CDOCProtocol *)protocol;
{
#ifdef ADD_SPACE
    if ([protocol.properties count] > 0 /*&& [aProtocol hasMethods]*/)
        [resultString appendString:@"\n"];
#endif
}

- (void)visitRemainingProperties:(CDVisitorPropertyState *)propertyState;
{
    NSArray *remaining = propertyState.remainingProperties;

    if ([remaining count] > 0) {
        [resultString appendString:@"\n"];
        [resultString appendFormat:@"// Remaining properties\n"];
        //NSLog(@"Warning: remaining undeclared property count: %u", [remaining count]);
        //NSLog(@"remaining: %@", remaining);
        for (CDOCProperty *property in remaining)
            [self visitProperty:property];
    }
}

#pragma mark -

@synthesize resultString;
@synthesize symbolReferences;

- (void)writeResultToStandardOutput;
{
    NSData *data = [resultString dataUsingEncoding:NSUTF8StringEncoding];
    [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];
}

- (void)_visitProperty:(CDOCProperty *)property parsedType:(CDType *)parsedType attributes:(NSArray *)attrs;
{
    NSString *backingVar = nil;
    BOOL isWeak = NO;
    BOOL isDynamic = NO;
    
    NSMutableArray *alist = [[NSMutableArray alloc] init];
    NSMutableArray *unknownAttrs = [[NSMutableArray alloc] init];
    
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
    
    NSString *formattedString = [self.classDump.typeController.propertyTypeFormatter formatVariable:property.name parsedType:parsedType symbolReferences:symbolReferences];
    [resultString appendFormat:@"%@;", formattedString];
    
    if (isDynamic) {
        [resultString appendFormat:@" // @dynamic %@;", property.name];
    } else if (backingVar != nil) {
        if ([backingVar isEqualToString:property.name]) {
            [resultString appendFormat:@" // @synthesize %@;", property.name];
        } else {
            [resultString appendFormat:@" // @synthesize %@=%@;", property.name, backingVar];
        }
    }
    
    [resultString appendString:@"\n"];
    if ([unknownAttrs count] > 0) {
        [resultString appendFormat:@"// Preceding property had unknown attributes: %@\n", [unknownAttrs componentsJoinedByString:@","]];
        if ([property.attributeString length] > 80) {
            [resultString appendFormat:@"// Original attribute string (following type): %@\n\n", property.attributeStringAfterType];
        } else {
            [resultString appendFormat:@"// Original attribute string: %@\n\n", property.attributeString];
        }
    }
}

@end
