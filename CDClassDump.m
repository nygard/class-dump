// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import "CDClassDump.h"

#import <Foundation/Foundation.h>
#import "NSArray-Extensions.h"
#import "CDDylibCommand.h"
#import "CDMachOFile.h"
#import "CDObjCSegmentProcessor.h"
#import "CDType.h"
#import "CDTypeFormatter.h"

@implementation CDClassDump2

- (id)init;
{
    if ([super init] == nil)
        return nil;

    //machOFiles = [[NSMutableArray alloc] init];
    machOFilesByID = [[NSMutableDictionary alloc] init];
    objCSegmentProcessors = [[NSMutableArray alloc] init];
    structCountsByType = [[NSMutableDictionary alloc] init];
    structsByName = [[NSMutableDictionary alloc] init];
    anonymousStructNames = [[NSMutableDictionary alloc] init];
    anonymousStructsByType = [[NSMutableDictionary alloc] init];
    anonymousRemapping = [[NSMutableDictionary alloc] init];

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
    [structDeclarationTypeFormatter setShouldAutoExpand:NO];
    [structDeclarationTypeFormatter setBaseLevel:0];

    return self;
}

- (void)dealloc;
{
    [machOFilesByID release];
    [objCSegmentProcessors release];
    [structCountsByType release];
    [structsByName release];
    [anonymousStructNames release];
    [anonymousStructsByType release];
    [anonymousRemapping release];
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
        {
            NSArray *keys;
            int count, index;
            NSString *key;

            keys = [[anonymousStructsByType allKeys] sortedArrayUsingSelector:@selector(compare:)];
            count = [keys count];
            for (index = 0; index < count; index++) {
                CDType *structType;
                NSString *bareTypeString;

                key = [keys objectAtIndex:index];
                structType = [anonymousStructsByType objectForKey:key];
                bareTypeString = [structType bareTypeString];
                if ([key isEqual:bareTypeString] == NO) {
                    NSNumber *thisCount, *oldCount;

                    // add this count to bare count (if it already exists)
                    thisCount = [structCountsByType objectForKey:key];
                    oldCount = [structCountsByType objectForKey:bareTypeString];
                    if (oldCount != nil) {
                        NSNumber *newCount;

                        newCount = [NSNumber numberWithInt:[thisCount intValue] + [oldCount intValue]];
                        [structCountsByType setObject:newCount forKey:bareTypeString];
                        [structCountsByType setObject:newCount forKey:key]; // Need to update both of 'em
                        [anonymousRemapping setObject:key forKey:bareTypeString];
                    }
                }
            }
        }

        {
            NSArray *keys;
            int count, index;
            NSString *key;

            keys = [[structCountsByType allKeys] sortedArrayUsingSelector:@selector(compare:)];
            count = [keys count];
            for (index = 0; index < count; index++) {
                key = [keys objectAtIndex:index];
                NSLog(@"%3d: %@ => %@", index, key, [structCountsByType objectForKey:key]);
            }

            // If a structure doesn't have any named members, it should be typedef'd
            // Any structure in a return value or argument should be typedef'd
        }

        {
            NSArray *keys;
            int count, index;
            NSString *key;

            NSLog(@"anonymousRemapping ----------------------------------------------------------------------");
            keys = [[anonymousRemapping allKeys] sortedArrayUsingSelector:@selector(compare:)];
            count = [keys count];
            for (index = 0; index < count; index++) {
                key = [keys objectAtIndex:index];
                NSLog(@"%3d: %@ => %@", index, key, [anonymousRemapping objectForKey:key]);
            }

            // If a structure doesn't have any named members, it should be typedef'd
            // Any structure in a return value or argument should be typedef'd
        }
#if 1
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
            NSLog(@"----------------------------------------------------------------------");
            keys = [[anonymousStructNames allKeys] sortedArrayUsingSelector:@selector(compare:)];
            count = [keys count];
            for (index = 0; index < count; index++) {
                key = [keys objectAtIndex:index];
                NSLog(@"%2d: %@ => %@", index, [anonymousStructNames objectForKey:key], key);
            }
        }
#endif
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
    [resultString appendString:@" *     class-dump is Copyright (C) 1997, 1999-2001, 2003 by Steve Nygard.\n"];
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

- (void)appendTypedefsToString:(NSMutableString *)resultString;
{
    NSArray *keys;
    int count, index;
    NSString *typeString, *formattedString, *name;

    keys = [[anonymousStructNames allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [keys count];
    if (count > 0)
        [resultString appendString:@"// Anonymous struct/union types\n"];

    for (index = 0; index < count; index++) {
        typeString = [keys objectAtIndex:index];
        if ([anonymousRemapping objectForKey:typeString] != nil)
            continue;

        name = [anonymousStructNames objectForKey:typeString];
        formattedString = [structDeclarationTypeFormatter formatVariable:nil type:typeString];
        if (formattedString != nil) {
            [resultString appendString:@"typedef "];
            [resultString appendString:formattedString];
            [resultString appendFormat:@" %@;\n\n", name];
        }
    }
}

//- (void)registerStructName:(NSString *)aName type:(NSString *)typeString;
- (void)registerStruct:(CDType *)structType name:(NSString *)aName;
{
    NSNumber *oldCount;
    NSString *typeString;

    typeString = [structType typeString];
    NSLog(@"%s, name: %@, typeString: %@", _cmd, aName, typeString);

    // Handle named structs
    if (aName != nil && [aName isEqual:@"?"] == NO) {
        CDType *existingType;

        if ([aName isEqual:@"objc_method_description"] == YES)
            NSLog(@"%@ => %@", aName, typeString);

        existingType = [structsByName objectForKey:aName];
        if (existingType == nil)
            [structsByName setObject:structType forKey:aName];
        else {
            NSLog(@"Merging %@ with %@", [existingType typeString], [structType typeString]);
            [existingType mergeWithType:structType];
            NSLog(@"Merged result: %@", [existingType typeString]);
        }
    }

    // Handle anonymous structs
    // TODO (2003-12-23): Count anonymous structs first, then assign names to ones used more than one time.
    if (aName == nil || [aName isEqual:@"?"] == YES) {
        CDType *previousType;
#if 1
        // Maybe we want to number them later, when we know which ones will be used.
        if ([anonymousStructNames objectForKey:typeString] == nil) {
            [anonymousStructNames setObject:[NSString stringWithFormat:@"CDAnonymousStruct%d", ++anonymousStructCounter] forKey:typeString];
        }
#endif
        previousType = [anonymousStructsByType objectForKey:typeString];
        if (previousType == nil)
            [anonymousStructsByType setObject:structType forKey:typeString];
        else {
            NSLog(@"Already registered this anonymoust struct, previous: %@, current: %@", [previousType typeString], typeString);
        }

        // Just count anonymous structs
        oldCount = [structCountsByType objectForKey:typeString];
        if (oldCount == nil)
            [structCountsByType setObject:[NSNumber numberWithInt:1] forKey:typeString];
        else
            [structCountsByType setObject:[NSNumber numberWithInt:[oldCount intValue] + 1] forKey:typeString];
    }
}

- (NSString *)typeFormatter:(CDTypeFormatter *)aFormatter typedefNameForStruct:(NSString *)structTypeString;
{
    NSString *remappedTypeString;

    // Count has been adjusted.

    // For ivars, only use typedef if the type is used > 1 time.
    if (/*aFormatter == [CDTypeFormatter sharedIvarTypeFormatter] || */aFormatter == ivarTypeFormatter) {
        if ([[structCountsByType objectForKey:structTypeString] intValue] < 2) {
            //NSLog(@"Just one of '%@'", structTypeString);
            return nil;
        }
    }

    remappedTypeString = [anonymousRemapping objectForKey:structTypeString];
    if (remappedTypeString != nil)
        structTypeString = remappedTypeString;

    return [anonymousStructNames objectForKey:structTypeString];
}

@end
