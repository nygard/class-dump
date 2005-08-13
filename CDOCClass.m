//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2005  Steve Nygard

#import "CDOCClass.h"

#import <Foundation/Foundation.h>
#import "NSArray-Extensions.h"
#import "CDClassDump.h"
#import "CDOCIvar.h"
#import "CDOCMethod.h"
#import "CDSymbolReferences.h"
#import "CDType.h"
#import "CDTypeParser.h"

@implementation CDOCClass

- (void)dealloc;
{
    [superClassName release];
    [ivars release];

    [super dealloc];
}

- (NSString *)superClassName;
{
    return superClassName;
}

- (void)setSuperClassName:(NSString *)newSuperClassName;
{
    if (newSuperClassName == superClassName)
        return;

    [superClassName release];
    superClassName = [newSuperClassName retain];
}

- (NSArray *)ivars;
{
    return ivars;
}

- (void)setIvars:(NSArray *)newIvars;
{
    if (newIvars == ivars)
        return;

    [ivars release];
    ivars = [newIvars retain];
}

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    int count, index;

    if ([aClassDump shouldMatchRegex] == YES && [aClassDump regexMatchesString:[self name]] == NO)
        return;

    [resultString appendFormat:@"@interface %@", name];
    if (superClassName != nil)
        [resultString appendFormat:@" : %@", superClassName];

    if ([protocols count] > 0) {
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];
        [symbolReferences addProtocolNamesFromArray:[protocols arrayByMappingSelector:@selector(name)]];
    }

    [resultString appendString:@"\n{\n"];
    count = [ivars count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            [[ivars objectAtIndex:index] appendToString:resultString classDump:aClassDump symbolReferences:symbolReferences];
            [resultString appendString:@"\n"];
        }
    }

    [resultString appendString:@"}\n\n"];
    [self appendMethodsToString:resultString classDump:aClassDump symbolReferences:symbolReferences];

    if ([classMethods count] > 0 || [instanceMethods count] > 0)
        [resultString appendString:@"\n"];
    [resultString appendString:@"@end\n\n"];
}

- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;
{
    int count, index;
    CDTypeParser *parser;

    [super registerStructuresWithObject:anObject phase:phase];

    count = [ivars count];
    for (index = 0; index < count; index++) {
        CDType *aType;

        parser = [[CDTypeParser alloc] initWithType:[(CDOCIvar *)[ivars objectAtIndex:index] type]];
        aType = [parser parseType];
        [aType phase:phase registerStructuresWithObject:anObject usedInMethod:NO];
        [parser release];
    }
}

//
// CDTopologicalSort protocol
//

- (NSString *)identifier;
{
    return [self name];
}

- (NSArray *)dependancies;
{
    if (superClassName == nil)
        return [NSArray array];

    return [NSArray arrayWithObject:superClassName];
}

@end
