//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDClassDump.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>
#import "NSArray-Extensions.h"
#import "CDDylibCommand.h"
#import "CDMachOFile.h"
#import "CDObjCSegmentProcessor.h"
#import "CDType.h"
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDClassDump.m,v 1.35 2004/01/07 21:26:47 nygard Exp $");

@implementation CDClassDump2

- (id)init;
{
    if ([super init] == nil)
        return nil;

    //machOFiles = [[NSMutableArray alloc] init];
    machOFilesByID = [[NSMutableDictionary alloc] init];
    objCSegmentProcessors = [[NSMutableArray alloc] init];
    anonymousStructCountsByType = [[NSMutableDictionary alloc] init];
    structsByName = [[NSMutableDictionary alloc] init];
    anonymousStructNamesByType = [[NSMutableDictionary alloc] init];
    anonymousStructsByType = [[NSMutableDictionary alloc] init];
    replacementTypes = [[NSMutableDictionary alloc] init];

    ivarTypeFormatter = [[CDTypeFormatter alloc] init];
    [ivarTypeFormatter setShouldExpand:NO];
    [ivarTypeFormatter setShouldAutoExpand:YES];
    [ivarTypeFormatter setBaseLevel:1];
    [ivarTypeFormatter setDelegate:self];

    methodTypeFormatter = [[CDTypeFormatter alloc] init];
    [methodTypeFormatter setShouldExpand:NO];
    [methodTypeFormatter setShouldAutoExpand:NO];
    [methodTypeFormatter setBaseLevel:0];
    [methodTypeFormatter setDelegate:self];

    structDeclarationTypeFormatter = [[CDTypeFormatter alloc] init];
    [structDeclarationTypeFormatter setShouldExpand:YES]; // But don't expand named struct members...
    [structDeclarationTypeFormatter setShouldAutoExpand:YES];
    [structDeclarationTypeFormatter setBaseLevel:0];

    NSLog(@"ivarTypeFormatter: %@", ivarTypeFormatter);
    NSLog(@"methodTypeFormatter: %@", methodTypeFormatter);
    NSLog(@"structDeclarationTypeFormatter: %@", structDeclarationTypeFormatter);

    return self;
}

- (void)dealloc;
{
    [machOFilesByID release];
    [objCSegmentProcessors release];
    [anonymousStructCountsByType release];
    [structsByName release];
    [anonymousStructNamesByType release];
    [anonymousStructsByType release];
    [replacementTypes release];
    [ivarTypeFormatter release];
    [methodTypeFormatter release];
    [structDeclarationTypeFormatter release];

    [super dealloc];
}

- (BOOL)shouldProcessRecursively;
{
    return shouldProcessRecursively;
}

- (void)setShouldProcessRecursively:(BOOL)newFlag;
{
    shouldProcessRecursively = newFlag;
}

- (CDTypeFormatter *)ivarTypeFormatter;
{
    return ivarTypeFormatter;
}

- (CDTypeFormatter *)methodTypeFormatter;
{
    return methodTypeFormatter;
}

- (CDTypeFormatter *)structDeclarationTypeFormatter;
{
    return structDeclarationTypeFormatter;
}

- (void)processFilename:(NSString *)aFilename;
{
    CDMachOFile *aMachOFile;
    CDObjCSegmentProcessor *aProcessor;

    //NSLog(@" > %s", _cmd);
    //NSLog(@"aFilename: %@", aFilename);

    aMachOFile = [[CDMachOFile alloc] initWithFilename:aFilename];
    [aMachOFile setDelegate:self];
    [aMachOFile process];

    aProcessor = [[CDObjCSegmentProcessor alloc] initWithMachOFile:aMachOFile];
    [aProcessor process];
    //NSLog(@"Formatted result:\n%@", [aProcessor formattedStringByClass]);
    [objCSegmentProcessors addObject:aProcessor];
    [aProcessor release];

    //[machOFiles addObject:aMachOFile];
    [machOFilesByID setObject:aMachOFile forKey:aFilename];

    [aMachOFile release];

    //NSLog(@"<  %s", _cmd);
}

// Some anonymous structs don't have member names, but others do.
// Here we find the structs with member names and check to see if
// there's an identical struct without names.  If there's only one
// we'll make the one without names use the one with names.  If
// there's more, though, we don't try to guess which it should be.

- (void)processIsomorphicStructs;
{
#if 1
    NSMutableDictionary *anonymousRemapping;
    NSArray *keys;
    int count, index;
    NSString *key;
    NSMutableArray *bares = [NSMutableArray array];
    NSMutableSet *duplicateMappings = [NSMutableSet set];

    NSLog(@"processIsomorphicStructs ----------------------------------------");
    anonymousRemapping = [[NSMutableDictionary alloc] init];

    keys = [[anonymousStructsByType allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [keys count];
    for (index = 0; index < count; index++) {
        CDType *structType;
        NSString *bareTypeString;

        key = [keys objectAtIndex:index];
        structType = [anonymousStructsByType objectForKey:key];
        bareTypeString = [structType bareTypeString];
        if ([key isEqual:bareTypeString] == NO) {
            //NSLog(@"%@ -> %@", key, bareTypeString);
            //NSLog(@"%@ <- %@", bareTypeString, key);
#if 1
            if ([duplicateMappings containsObject:bareTypeString] == NO) {
                NSString *existingValue;

                existingValue = [anonymousRemapping objectForKey:bareTypeString];
                if (existingValue == nil) {
                    [anonymousRemapping setObject:key forKey:bareTypeString];
                } else {
                    [duplicateMappings addObject:bareTypeString];
                    [anonymousRemapping removeObjectForKey:bareTypeString];
                }
            }
#endif
            [bares addObject:bareTypeString];
#if 0
            NSNumber *thisCount, *oldCount;

            // add this count to bare count (if it already exists)
            thisCount = [anonymousStructCountsByType objectForKey:key];
            oldCount = [anonymousStructCountsByType objectForKey:bareTypeString];
            if (oldCount != nil) {
                NSNumber *newCount;

                newCount = [NSNumber numberWithInt:[thisCount intValue] + [oldCount intValue]];
                [anonymousStructCountsByType setObject:newCount forKey:bareTypeString];
                [anonymousStructCountsByType setObject:newCount forKey:key]; // Need to update both of 'em
                [anonymousRemapping setObject:key forKey:bareTypeString];
            }
#endif
        }
    }

    [bares sortUsingSelector:@selector(compare:)];
    NSLog(@"bares: %@", [bares description]);
#endif

    // Now we need to combine anything that gets remapped.
    {
        NSArray *mapKeys;
        NSString *originalType, *replacementType;

        mapKeys = [anonymousRemapping allKeys];
        count = [mapKeys count];
        for (index = 0; index < count; index++) {
            int newCount;

            originalType = [mapKeys objectAtIndex:index];
            replacementType = [anonymousRemapping objectForKey:originalType];
            newCount = [[anonymousStructCountsByType objectForKey:originalType] intValue] + [[anonymousStructCountsByType objectForKey:replacementType] intValue];

            NSLog(@"Combining %@ with %@", originalType, replacementType);
            [anonymousStructCountsByType setObject:[NSNumber numberWithInt:newCount] forKey:replacementType];
            [anonymousStructCountsByType removeObjectForKey:originalType];
            [anonymousStructsByType removeObjectForKey:originalType];

            [self replaceTypeString:originalType withTypeString:replacementType];
        }
    }

    [anonymousRemapping release];
}

- (void)replaceTypeString:(NSString *)originalTypeString withTypeString:(NSString *)replacementTypeString;
{
    CDTypeParser *aTypeParser;
    CDType *replacementType;

    aTypeParser = [[CDTypeParser alloc] initWithType:replacementTypeString];
    replacementType = [aTypeParser parseType];
    if (replacementType != nil)
        [replacementTypes setObject:replacementType forKey:originalTypeString];
}

// First, let's just name all of them.
- (void)generateNamesForAnonymousStructs;
{
    int nameIndex = 1;
    NSArray *keys;
    int count, index;
    NSString *key;

    keys = [anonymousStructsByType allKeys];
    count = [keys count];
    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        [anonymousStructNamesByType setObject:[NSString stringWithFormat:@"CDAnonymousStruct%d", nameIndex++] forKey:key];
    }
}

- (void)logStructCounts;
{
    NSArray *keys;
    int count, index;
    NSString *key;

    NSLog(@" > %s", _cmd);
    keys = [[anonymousStructCountsByType allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [keys count];
    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        NSLog(@"%3d: %@ => %@", index, key, [anonymousStructCountsByType objectForKey:key]);
    }

    // If a structure doesn't have any named members, it should be typedef'd
    // Any structure in a return value or argument should be typedef'd
    NSLog(@"<  %s", _cmd);
}

- (void)logAnonymousRemappings;
{
    NSArray *keys;
    int count, index;
    NSString *key;

    NSLog(@"replacement types ----------------------------------------------------------------------");
    keys = [[replacementTypes allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [keys count];
    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        NSLog(@"%3d: %@ => %@", index, key, [[replacementTypes objectForKey:key] typeString]);
    }

    // If a structure doesn't have any named members, it should be typedef'd
    // Any structure in a return value or argument should be typedef'd
}

- (void)logNamedStructs;
{
    NSArray *keys;
    NSString *key;
    int count, index;

    NSLog(@"----------------------------------------------------------------------");
    keys = [[structsByName allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [keys count];
    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        NSLog(@"%2d: %@ => %@", index, key, [[structsByName objectForKey:key] typeString]);
    }
}

- (void)logAnonymousStructs;
{
    NSArray *keys;
    NSString *key;
    int count, index;

    NSLog(@"----------------------------------------------------------------------");
    keys = [[anonymousStructNamesByType allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [keys count];
    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        NSLog(@"%2d: %@ => %@", index, [anonymousStructNamesByType objectForKey:key], key);
    }
}

- (void)doSomething;
{
    NSLog(@"machOFilesByID keys: %@", [[machOFilesByID allKeys] description]);
    //NSLog(@"machOFiles in order: %@", [[machOFiles arrayByMappingSelector:@selector(filename)] description]);
    NSLog(@"objCSegmentProcessors in order: %@", [objCSegmentProcessors description]);

    {
        NSMutableString *resultString;
        int count, index;

        count = [objCSegmentProcessors count];
        for (index = 0; index < count; index++) {
            [[objCSegmentProcessors objectAtIndex:index] registerStructsWithObject:self];
        }

        // Check for isomorphic structs, one of which may not have had named members
        [self processIsomorphicStructs];
        [self generateNamesForAnonymousStructs];
        [self logStructCounts];
        [self logAnonymousRemappings];

        [self logNamedStructs];
        [self logAnonymousStructs];

        resultString = [[NSMutableString alloc] init];
        [self appendHeaderToString:resultString];

        [self appendNamedStructsToString:resultString];
        [self appendTypedefsToString:resultString];

        for (index = 0; index < count; index++) {
            [[objCSegmentProcessors objectAtIndex:index] appendFormattedStringSortedByClass:resultString classDump:self];
        }

#if 1
        {
            NSData *data;

            data = [resultString dataUsingEncoding:NSUTF8StringEncoding];
            [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];
        }
        //NSLog(@"formatted result:\n%@", resultString);
#else
        // For sampling
        NSLog(@"Done...........");
        sleep(5);
#endif
        [resultString release];
    }
}

- (CDMachOFile *)machOFileWithID:(NSString *)anID;
{
    CDMachOFile *aMachOFile;

    //NSLog(@" > %s", _cmd);
    //NSLog(@"anID: %@", anID);

    aMachOFile = [machOFilesByID objectForKey:anID];
    if (aMachOFile == nil) {
        [self processFilename:anID];
        aMachOFile = [machOFilesByID objectForKey:anID];
    }
    //NSLog(@"<  %s", _cmd);

    return aMachOFile;
}

- (void)machOFile:(CDMachOFile *)aMachOFile loadDylib:(CDDylibCommand *)aDylibCommand;
{
    //NSLog(@" > %s", _cmd);
    //NSLog(@"aDylibCommand: %@", aDylibCommand);

    if ([aDylibCommand cmd] == LC_LOAD_DYLIB && shouldProcessRecursively == YES) {
        //NSLog(@"Load it!");
        [self machOFileWithID:[aDylibCommand name]];
    }

    //NSLog(@"<  %s", _cmd);
}

- (void)appendHeaderToString:(NSMutableString *)resultString;
{
    [resultString appendString:@"/*\n"];
    [resultString appendString:@" *     Generated by class-dump (version 3.0 alpha).\n"];
    [resultString appendString:@" *\n"];
    [resultString appendString:@" *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004 by Steve Nygard.\n"];
    [resultString appendString:@" */\n\n"];
}

// TODO (2003-12-23): Add option to show/hide this section
// TODO (2003-12-23): auto-name unnamed members
// TODO (2003-12-23): sort by name or by dependency
// TODO (2003-12-23): declare in modules where they were first used

- (void)appendNamedStructsToString:(NSMutableString *)resultString;
{
    NSArray *keys;
    NSString *key;
    int count, index;
    NSString *formattedString;
    CDType *type;

    keys = [[structsByName allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [keys count];
    if (count > 0)
        [resultString appendString:@"// Named struct/union types\n"];

    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        type = [structsByName objectForKey:key];
        formattedString = [structDeclarationTypeFormatter formatVariable:nil type:[type typeString]];
        if (formattedString != nil) {
            [resultString appendString:formattedString];
            [resultString appendString:@";\n\n"];
        }
    }
}

// Any structure in a return value or argument should be typedef'd
- (void)appendTypedefsToString:(NSMutableString *)resultString;
{
    NSArray *keys;
    int count, index;
    NSString *typeString, *formattedString, *name;
    BOOL hasAddedComment = NO;

    //keys = [[anonymousStructNamesByType allKeys] sortedArrayUsingSelector:@selector(compare:)];
    keys = [anonymousStructNamesByType allKeys];
    count = [keys count];

    for (index = 0; index < count; index++) {
        typeString = [keys objectAtIndex:index];

        if (1/*[[anonymousStructCountsByType objectForKey:typeString] intValue] > 1*/) {
            name = [anonymousStructNamesByType objectForKey:typeString];
            formattedString = [structDeclarationTypeFormatter formatVariable:nil type:typeString];
            if (formattedString != nil) {
                if (hasAddedComment == NO) {
                    [resultString appendString:@"// Anonymous struct/union types\n"];
                    hasAddedComment = YES;
                }
                [resultString appendString:@"typedef "];
                [resultString appendString:formattedString];
                [resultString appendFormat:@" %@;\n\n", name];
            }
        }
    }
}

- (void)registerStruct:(CDType *)structType name:(NSString *)aName countReferences:(BOOL)shouldCountReferences;
{
    NSNumber *oldCount;
    NSString *typeString;

    typeString = [structType typeString];
    //NSLog(@"%s, name: %@, typeString: %@", _cmd, aName, typeString);

    // First, register member structs
    //[structType registerMemberStructsWithObject:self];

    // Handle named structs
    if (aName != nil && [aName isEqual:@"?"] == NO) {
        CDType *existingType;

        if ([aName isEqual:@"objc_method_description"] == YES)
            NSLog(@"%@ => %@", aName, typeString);

        existingType = [structsByName objectForKey:aName];
        if (existingType == nil) {
            [structType registerMemberStructsWithObject:self countReferences:shouldCountReferences];
            [structsByName setObject:structType forKey:aName];
        } else if ([structType isEqual:existingType] == NO) {
            NSString *before;

            [structType registerMemberStructsWithObject:self countReferences:NO];
            before = [existingType typeString];
            [existingType mergeWithType:structType];
            if ([before isEqual:[existingType typeString]] == NO) {
                NSLog(@"Merging %@ with %@", before, [structType typeString]);
                NSLog(@"Merged result: %@", [existingType typeString]);
            } else {
                //NSLog(@"No change from merging types.");
            }
        }
    }

    // Handle anonymous structs
    // TODO (2003-12-23): Count anonymous structs first, then assign names to ones used more than one time.
    if (aName == nil || [aName isEqual:@"?"] == YES) {
        CDType *previousType;

        //NSLog(@"%s, name: %@, typeString: %@", _cmd, aName, typeString);
#if 0
        // Maybe we want to number them later, when we know which ones will be used.
        if ([anonymousStructNamesByType objectForKey:typeString] == nil) {
            [anonymousStructNamesByType setObject:[NSString stringWithFormat:@"CDAnonymousStruct%d", ++anonymousStructCounter] forKey:typeString];
        }
#endif
        previousType = [anonymousStructsByType objectForKey:typeString];
        if (previousType == nil)
            [anonymousStructsByType setObject:structType forKey:typeString];
        else {
            NSLog(@"Already registered this anonymous struct, previous: %@, current: %@", [previousType typeString], typeString);
        }

        // Just count anonymous structs
        oldCount = [anonymousStructCountsByType objectForKey:typeString];
        if (oldCount == nil)
            [anonymousStructCountsByType setObject:[NSNumber numberWithInt:1] forKey:typeString];
        else
            [anonymousStructCountsByType setObject:[NSNumber numberWithInt:[oldCount intValue] + 1] forKey:typeString];
    }
}

- (CDType *)typeFormatter:(CDTypeFormatter *)aFormatter replacementForType:(CDType *)aType;
{
    return [replacementTypes objectForKey:[aType typeString]];
}

- (NSString *)typeFormatter:(CDTypeFormatter *)aFormatter typedefNameForStruct:(NSString *)structTypeString;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"structTypeString: %@", structTypeString);

    return nil;
    // Count has been adjusted.

    // For ivars, only use typedef if the type is used > 1 time.
    if (1/*aFormatter == ivarTypeFormatter*/) {
        if ([[anonymousStructCountsByType objectForKey:structTypeString] intValue] < 2) {
            NSLog(@"Just one of '%@'", structTypeString);
            NSLog(@"<  %s", _cmd);
            return nil;
        }
    }

    NSLog(@"<  %s", _cmd);
    return [anonymousStructNamesByType objectForKey:structTypeString];
}

@end
