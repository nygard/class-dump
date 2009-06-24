// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDClassDump.h"

#import <Foundation/Foundation.h>
#import "NSArray-Extensions.h"
#import "NSString-Extensions.h"
#import "CDFatArch.h"
#import "CDFatFile.h"
#import "CDLCDylib.h"
#import "CDMachOFile.h"
#import "CDObjCSegmentProcessor.h"
#import "CDStructureTable.h"
#import "CDSymbolReferences.h"
#import "CDType.h"
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"
#import "CDVisitor.h"

@implementation CDClassDump

- (id)init;
{
    if ([super init] == nil)
        return nil;

    executablePath = nil;

    machOFiles = [[NSMutableArray alloc] init];
    machOFilesByID = [[NSMutableDictionary alloc] init];
    objCSegmentProcessors = [[NSMutableArray alloc] init];

    structureTable = [[CDStructureTable alloc] init];
    [structureTable setAnonymousBaseName:@"CDAnonymousStruct"];
    [structureTable setName:@"Structs"];

    unionTable = [[CDStructureTable alloc] init];
    [unionTable setAnonymousBaseName:@"CDAnonymousUnion"];
    [unionTable setName:@"Unions"];

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
    [structDeclarationTypeFormatter setDelegate:self]; // But need to ignore some things?

    // These can be ppc, ppc7400, ppc64, i386, x86_64
    targetArchName = nil;

    flags.shouldShowHeader = YES;

    return self;
}

- (void)dealloc;
{
    [executablePath release];

    [machOFiles release];
    [machOFilesByID release];
    [objCSegmentProcessors release];

    [structureTable release];
    [unionTable release];

    [ivarTypeFormatter release];
    [methodTypeFormatter release];
    [structDeclarationTypeFormatter release];

    if (flags.shouldMatchRegex == YES)
        regfree(&compiledRegex);

    [targetArchName release];

    [super dealloc];
}

- (NSString *)executablePath;
{
    return executablePath;
}

- (void)setExecutablePath:(NSString *)newPath;
{
    if (newPath == executablePath)
        return;

    [executablePath release];
    executablePath = [newPath retain];
}

- (BOOL)shouldProcessRecursively;
{
    return flags.shouldProcessRecursively;
}

- (void)setShouldProcessRecursively:(BOOL)newFlag;
{
    flags.shouldProcessRecursively = newFlag;
}

- (BOOL)shouldSortClasses;
{
    return flags.shouldSortClasses;
}

- (void)setShouldSortClasses:(BOOL)newFlag;
{
    flags.shouldSortClasses = newFlag;
}

- (BOOL)shouldSortClassesByInheritance;
{
    return flags.shouldSortClassesByInheritance;
}

- (void)setShouldSortClassesByInheritance:(BOOL)newFlag;
{
    flags.shouldSortClassesByInheritance = newFlag;
}

- (BOOL)shouldSortMethods;
{
    return flags.shouldSortMethods;
}

- (void)setShouldSortMethods:(BOOL)newFlag;
{
    flags.shouldSortMethods = newFlag;
}

- (BOOL)shouldShowIvarOffsets;
{
    return flags.shouldShowIvarOffsets;
}

- (void)setShouldShowIvarOffsets:(BOOL)newFlag;
{
    flags.shouldShowIvarOffsets = newFlag;
}

- (BOOL)shouldShowMethodAddresses;
{
    return flags.shouldShowMethodAddresses;
}

- (void)setShouldShowMethodAddresses:(BOOL)newFlag;
{
    flags.shouldShowMethodAddresses = newFlag;
}

- (BOOL)shouldMatchRegex;
{
    return flags.shouldMatchRegex;
}

- (void)setShouldMatchRegex:(BOOL)newFlag;
{
    if (flags.shouldMatchRegex == YES && newFlag == NO)
        regfree(&compiledRegex);

    flags.shouldMatchRegex = newFlag;
}

- (BOOL)shouldShowHeader;
{
    return flags.shouldShowHeader;
}

- (void)setShouldShowHeader:(BOOL)newFlag;
{
    flags.shouldShowHeader = newFlag;
}

- (BOOL)setRegex:(char *)regexCString errorMessage:(NSString **)errorMessagePointer;
{
    int result;

    if (flags.shouldMatchRegex == YES)
        regfree(&compiledRegex);

    result = regcomp(&compiledRegex, regexCString, REG_EXTENDED);
    if (result != 0) {
        char regex_error_buffer[256];

        if (regerror(result, &compiledRegex, regex_error_buffer, 256) > 0) {
            if (errorMessagePointer != NULL) {
                *errorMessagePointer = [NSString stringWithCString:regex_error_buffer];
            }
        } else {
            if (errorMessagePointer != NULL)
                *errorMessagePointer = nil;
        }

        return NO;
    }

    [self setShouldMatchRegex:YES];

    return YES;
}

- (BOOL)regexMatchesString:(NSString *)aString;
{
    int result;

    result = regexec(&compiledRegex, [aString UTF8String], 0, NULL, 0);
    if (result != 0) {
        if (result != REG_NOMATCH) {
            char regex_error_buffer[256];

            if (regerror(result, &compiledRegex, regex_error_buffer, 256) > 0)
                NSLog(@"Error with regex matching string, %@", [NSString stringWithCString:regex_error_buffer]);
        }

        return NO;
    }

    return YES;
}

- (NSArray *)machOFiles;
{
    return machOFiles;
}

- (NSArray *)objCSegmentProcessors;
{
    return objCSegmentProcessors;
}

- (NSString *)targetArchName;
{
    return targetArchName;
}

- (void)setTargetArchName:(NSString *)newArchName;
{
    NSLog(@"new: %@, old: %@", newArchName, targetArchName);
    if (newArchName == targetArchName)
        return;

    [targetArchName release];
    targetArchName = [newArchName retain];
}

- (BOOL)containsObjectiveCSegments;
{
    for (CDObjCSegmentProcessor *processor in objCSegmentProcessors) {
        if ([processor hasModules])
            return YES;
    }

    return NO;
}

- (CDStructureTable *)structureTable;
{
    return structureTable;
}

- (CDStructureTable *)unionTable;
{
    return unionTable;
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

// Return YES if successful, NO if there was an error.
- (BOOL)_processFilename:(NSString *)aFilename;
{
    NSData *data;
    CDFile *aFile;

    data = [[NSData alloc] initWithContentsOfMappedFile:aFilename];

    aFile = [CDFile fileWithData:data];
    NSLog(@"aFile: %@", aFile);
    [aFile setFilename:aFilename];

    [data release];

    if (aFile == nil)
        return NO;

    return [self processFile:aFile];
}

- (BOOL)processFile:(CDFile *)aFile;
{
    CDMachOFile *aMachOFile;

    // We need to find the macho file with the target arch name, set it to aMachOFile
    aMachOFile = [aFile machOFileWithArchName:targetArchName];
    NSLog(@"aMachOFile: %@", aMachOFile);
    NSLog(@"load commands: %@", [aMachOFile loadCommands]);
    {
    }

    if ([self shouldProcessRecursively]) {
        @try {
            for (CDLoadCommand *loadCommand in [aMachOFile loadCommands]) {
                if ([loadCommand isKindOfClass:[CDLCDylib class]]) {
                    CDLCDylib *aDylibCommand;

                    aDylibCommand = (CDLCDylib *)loadCommand;
                    if ([aDylibCommand cmd] == LC_LOAD_DYLIB)
                        [self machOFileWithID:[aDylibCommand name]]; // Processes as a side effect
                }
            }
        }
        @catch (NSException *exception) {
            [aMachOFile release];
            return NO;
        }
    }

    assert([aMachOFile filename] != nil);
    [machOFiles addObject:aMachOFile];
    [machOFilesByID setObject:aMachOFile forKey:[aMachOFile filename]];

    return YES;
}

- (void)processObjectiveCSegments;
{
    for (CDMachOFile *machOFile in machOFiles) {
        CDObjCSegmentProcessor *aProcessor;

        NSLog(@"----------------------------------------------------------------------");
        aProcessor = [[CDObjCSegmentProcessor alloc] initWithMachOFile:machOFile];
        [aProcessor process];
        [objCSegmentProcessors addObject:aProcessor];
        [aProcessor release];
    }
}

// This visits everything segment processors, classes, categories.  It skips over modules.  Need something to visit modules so we can generate separate headers.
- (void)recursivelyVisit:(CDVisitor *)aVisitor;
{
    [aVisitor willBeginVisiting];

    if ([self containsObjectiveCSegments]) {
        for (CDObjCSegmentProcessor *processor in objCSegmentProcessors)
            [processor recursivelyVisit:aVisitor];
    }

    [aVisitor didEndVisiting];
}

- (void)registerStuff;
{
    [self registerPhase:1];
    [self registerPhase:2];
    [self generateMemberNames];
}

- (void)logInfo;
{
    [structureTable logInfo];
    [unionTable logInfo];
}

- (void)appendStructuresToString:(NSMutableString *)resultString symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    [structureTable appendNamedStructuresToString:resultString classDump:self formatter:structDeclarationTypeFormatter symbolReferences:symbolReferences];
    [structureTable appendTypedefsToString:resultString classDump:self formatter:structDeclarationTypeFormatter symbolReferences:symbolReferences];

    [unionTable appendNamedStructuresToString:resultString classDump:self formatter:structDeclarationTypeFormatter symbolReferences:symbolReferences];
    [unionTable appendTypedefsToString:resultString classDump:self formatter:structDeclarationTypeFormatter symbolReferences:symbolReferences];
}

- (CDMachOFile *)machOFileWithID:(NSString *)anID;
{
    NSString *adjustedID;
    CDMachOFile *aMachOFile;
    NSString *replacementString = @"@executable_path";

    if ([anID hasPrefix:replacementString] == YES) {
        adjustedID = [executablePath stringByAppendingString:[anID substringFromIndex:[replacementString length]]];
    } else {
        adjustedID = anID;
    }

    aMachOFile = [machOFilesByID objectForKey:adjustedID];
    if (aMachOFile == nil) {
        [self _processFilename:adjustedID];
        aMachOFile = [machOFilesByID objectForKey:adjustedID];
    }

    return aMachOFile;
}

- (void)appendHeaderToString:(NSMutableString *)resultString;
{
    // Since this changes each version, for regression testing it'll be better to be able to not show it.
    if (flags.shouldShowHeader == NO)
        return;

    [resultString appendString:@"/*\n"];
    [resultString appendFormat:@" *     Generated by class-dump %s.\n", CLASS_DUMP_VERSION];
    [resultString appendString:@" *\n"];
    [resultString appendString:@" *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2009 by Steve Nygard.\n"];
    [resultString appendString:@" */\n\n"];
}

- (CDType *)typeFormatter:(CDTypeFormatter *)aFormatter replacementForType:(CDType *)aType;
{
    if ([aType type] == '{')
        return [structureTable replacementForType:aType];

    if ([aType type] == '(')
        return [unionTable replacementForType:aType];

    return nil;
}

- (NSString *)typeFormatter:(CDTypeFormatter *)aFormatter typedefNameForStruct:(CDType *)structType level:(int)level;
{
    CDType *searchType;
    CDStructureTable *targetTable;

    if (level == 0 && aFormatter == structDeclarationTypeFormatter)
        return nil;

    if ([structType type] == '{') {
        targetTable = structureTable;
    } else {
        targetTable = unionTable;
    }

    // We need to catch top level replacements, not just replacements for struct members.
    searchType = [targetTable replacementForType:structType];
    if (searchType == nil)
        searchType = structType;

    return [targetTable typedefNameForStructureType:searchType];
}

- (void)registerPhase:(int)phase;
{
    NSAutoreleasePool *pool;

    pool = [[NSAutoreleasePool alloc] init];

    for (CDObjCSegmentProcessor *processor in objCSegmentProcessors) {
        [processor registerStructuresWithObject:self phase:phase];
    }

    [self endPhase:phase];
    [pool release];
}

- (void)endPhase:(int)phase;
{
    if (phase == 1) {
        [structureTable finishPhase1];
        [unionTable finishPhase1];
    } else if (phase == 2) {
        [structureTable generateNamesForAnonymousStructures];
        [unionTable generateNamesForAnonymousStructures];
    }
}

- (void)phase1RegisterStructure:(CDType *)aStructure;
{
    if ([aStructure type] == '{') {
        [structureTable phase1RegisterStructure:aStructure];
    } else if ([aStructure type] == '(') {
        [unionTable phase1RegisterStructure:aStructure];
    } else {
        NSLog(@"%s, unknown structure type: %d", _cmd, [aStructure type]);
    }
}

- (BOOL)phase2RegisterStructure:(CDType *)aStructure usedInMethod:(BOOL)isUsedInMethod countReferences:(BOOL)shouldCountReferences;
{
    if ([aStructure type] == '{') {
        return [structureTable phase2RegisterStructure:aStructure withObject:self usedInMethod:isUsedInMethod countReferences:shouldCountReferences];
    } else if ([aStructure type] == '(') {
        return [unionTable phase2RegisterStructure:aStructure withObject:self usedInMethod:isUsedInMethod countReferences:shouldCountReferences];
    } else {
        NSLog(@"%s, unknown structure type: %d", _cmd, [aStructure type]);
    }

    return NO;
}

- (void)generateMemberNames;
{
    [structureTable generateMemberNames];
    [unionTable generateMemberNames];
}

- (void)showHeader;
{
    if ([machOFiles count] > 0) {
        [[[machOFiles lastObject] headerString:YES] print];
    }
}

- (void)showLoadCommands;
{
    if ([machOFiles count] > 0) {
        [[[machOFiles lastObject] loadCommandString:YES] print];
    }
}

@end
