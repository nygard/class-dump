// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import "CDClassDump.h"

#import <Foundation/Foundation.h>
#import "NSArray-Extensions.h"
#import "CDDylibCommand.h"
#import "CDMachOFile.h"
#import "CDObjCSegmentProcessor.h"
#import "CDTypeFormatter.h"

@implementation CDClassDump2

- (id)init;
{
    if ([super init] == nil)
        return nil;

    //machOFiles = [[NSMutableArray alloc] init];
    machOFilesByID = [[NSMutableDictionary alloc] init];
    objCSegmentProcessors = [[NSMutableArray alloc] init];
    structCounts = [[NSMutableDictionary alloc] init];
    structsByName = [[NSMutableDictionary alloc] init];
    anonymousStructs = [[NSMutableDictionary alloc] init];

    return self;
}

- (void)dealloc;
{
    //[machOFiles release];
    [machOFilesByID release];
    [objCSegmentProcessors release];
    [structCounts release];
    [structsByName release];
    [anonymousStructs release];

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

- (void)processFilename:(NSString *)aFilename;
{
    CDMachOFile *aMachOFile;
    CDObjCSegmentProcessor *aProcessor;

    NSLog(@" > %s", _cmd);
    NSLog(@"aFilename: %@", aFilename);

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

    NSLog(@"<  %s", _cmd);
}

- (void)doSomething;
{
    NSLog(@"machOFilesByID keys: %@", [[machOFilesByID allKeys] description]);
    //NSLog(@"machOFiles in order: %@", [[machOFiles arrayByMappingSelector:@selector(filename)] description]);
    NSLog(@"objCSegmentProcessors in order: %@", [objCSegmentProcessors description]);

    //[[CDTypeFormatter sharedTypeFormatter] setDelegate:self];
    [[CDTypeFormatter sharedIvarTypeFormatter] setDelegate:self];
    [[CDTypeFormatter sharedMethodTypeFormatter] setDelegate:self];
    //[[CDTypeFormatter sharedStructDeclarationTypeFormatter] setDelegate:self];

    {
        NSMutableString *resultString;
        int count, index;

        count = [objCSegmentProcessors count];
        for (index = 0; index < count; index++) {
            [[objCSegmentProcessors objectAtIndex:index] registerStructsWithObject:self];
        }

        {
            NSArray *keys;
            int count, index;
            NSString *key;

            keys = [[structCounts allKeys] sortedArrayUsingSelector:@selector(compare:)];
            count = [keys count];
            for (index = 0; index < count; index++) {
                key = [keys objectAtIndex:index];
                NSLog(@"%3d: %@ => %@", index, key, [structCounts objectForKey:key]);
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
                NSLog(@"%2d: %@ => %@", index, key, [structsByName objectForKey:key]);
            }
            NSLog(@"----------------------------------------------------------------------");
            keys = [[anonymousStructs allKeys] sortedArrayUsingSelector:@selector(compare:)];
            count = [keys count];
            for (index = 0; index < count; index++) {
                key = [keys objectAtIndex:index];
                NSLog(@"%2d: %@ => %@", index, [anonymousStructs objectForKey:key], key);
            }
        }
#endif
        resultString = [[NSMutableString alloc] init];
        [self appendHeaderToString:resultString];

        [self appendNamedStructsToString:resultString];
        [self appendTypedefsToString:resultString];

        for (index = 0; index < count; index++) {
            [[objCSegmentProcessors objectAtIndex:index] appendFormattedStringSortedByClass:resultString];
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

    //[[CDTypeFormatter sharedTypeFormatter] setDelegate:nil];
    [[CDTypeFormatter sharedIvarTypeFormatter] setDelegate:nil];
    [[CDTypeFormatter sharedMethodTypeFormatter] setDelegate:nil];
    //[[CDTypeFormatter sharedStructDeclarationTypeFormatter] setDelegate:nil];
}

- (CDMachOFile *)machOFileWithID:(NSString *)anID;
{
    CDMachOFile *aMachOFile;

    NSLog(@" > %s", _cmd);
    NSLog(@"anID: %@", anID);

    aMachOFile = [machOFilesByID objectForKey:anID];
    if (aMachOFile == nil) {
        [self processFilename:anID];
        aMachOFile = [machOFilesByID objectForKey:anID];
    }
    NSLog(@"<  %s", _cmd);

    return aMachOFile;
}

- (void)machOFile:(CDMachOFile *)aMachOFile loadDylib:(CDDylibCommand *)aDylibCommand;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"aDylibCommand: %@", aDylibCommand);

    if ([aDylibCommand cmd] == LC_LOAD_DYLIB && shouldProcessRecursively == YES) {
        NSLog(@"Load it!");
        [self machOFileWithID:[aDylibCommand name]];
    }

    NSLog(@"<  %s", _cmd);
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
// TODO (2003-12-23): declare in modules where they were fist used

- (void)appendNamedStructsToString:(NSMutableString *)resultString;
{
    NSArray *keys;
    NSString *key;
    int count, index;
    NSString *typeString, *formattedString;

    keys = [[structsByName allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [keys count];
    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        typeString = [structsByName objectForKey:key];
        formattedString = [[CDTypeFormatter sharedStructDeclarationTypeFormatter] formatVariable:nil type:typeString atLevel:0];
        if (formattedString != nil) {
            [resultString appendString:formattedString];
            [resultString appendString:@";\n\n"];
        }
    }
}

- (void)appendTypedefsToString:(NSMutableString *)resultString;
{
    NSArray *keys;
    //NSString *key;
    int count, index;
    NSString *typeString, *formattedString, *name;

    keys = [[anonymousStructs allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [keys count];
    for (index = 0; index < count; index++) {
        typeString = [keys objectAtIndex:index];
        name = [anonymousStructs objectForKey:typeString];
        formattedString = [[CDTypeFormatter sharedStructDeclarationTypeFormatter] formatVariable:nil type:typeString atLevel:0]; // TODO (2003-12-23): Need to replace
        if (formattedString != nil) {
            [resultString appendString:@"typedef "];
            [resultString appendString:formattedString];
            [resultString appendFormat:@" %@;\n\n", name];
        }
    }
}

- (void)registerStructName:(NSString *)aName type:(NSString *)typeString;
{
    NSNumber *oldCount;

    NSLog(@"%s, name: %@, typeString: %@", _cmd, aName, typeString);

    // Handle named structs
    if (aName != nil && [aName isEqual:@"?"] == NO) {
        NSString *existingTypeString;

        existingTypeString = [structsByName objectForKey:aName];
        if (existingTypeString == nil)
            [structsByName setObject:typeString forKey:aName];
        else {
            assert([typeString isEqual:existingTypeString] == YES);
        }
    }

    // Handle anonymous structs
    // TODO (2003-12-23): Count anonymous structs first, then assign names to ones used more than one time.
    if (aName == nil || [aName isEqual:@"?"] == YES) {
        if ([anonymousStructs objectForKey:typeString] == nil) {
            [anonymousStructs setObject:[NSString stringWithFormat:@"CDAnonymousStruct%d", ++anonymousStructCounter] forKey:typeString];
        }
    }

    oldCount = [structCounts objectForKey:typeString];
    if (oldCount == nil)
        [structCounts setObject:[NSNumber numberWithInt:1] forKey:typeString];
    else
        [structCounts setObject:[NSNumber numberWithInt:[oldCount intValue] + 1] forKey:typeString];
}

- (NSString *)typedefNameForStruct:(NSString *)structTypeString;
{
    NSLog(@"%s, result = %@", _cmd, [anonymousStructs objectForKey:structTypeString]);
    return [anonymousStructs objectForKey:structTypeString];
}

@end
