// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDClassDump.h"

#import "NSArray-Extensions.h"
#import "NSString-Extensions.h"
#import "CDFatArch.h"
#import "CDFatFile.h"
#import "CDLCDylib.h"
#import "CDMachOFile.h"
#import "CDObjectiveCProcessor.h"
#import "CDStructureTable.h"
#import "CDSymbolReferences.h"
#import "CDType.h"
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"
#import "CDVisitor.h"
#import "CDLCSegment.h"
#import "CDTypeController.h"
#import "CDSearchPathState.h"

@implementation CDClassDump

- (id)init;
{
    if ([super init] == nil)
        return nil;

    searchPathState = [[CDSearchPathState alloc] init];
    sdkRoot = nil;

    machOFiles = [[NSMutableArray alloc] init];
    machOFilesByID = [[NSMutableDictionary alloc] init];
    objcProcessors = [[NSMutableArray alloc] init];

    typeController = [[CDTypeController alloc] initWithClassDump:self];

    // These can be ppc, ppc7400, ppc64, i386, x86_64
    targetArch.cputype = CPU_TYPE_ANY;
    targetArch.cpusubtype = 0;

    flags.shouldShowHeader = YES;

    return self;
}

- (void)dealloc;
{
    [searchPathState release];
    [sdkRoot release];

    [machOFiles release];
    [machOFilesByID release];
    [objcProcessors release];

    [typeController release];

    if (flags.shouldMatchRegex)
        regfree(&compiledRegex);

    [super dealloc];
}

@synthesize searchPathState;

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
    if (flags.shouldMatchRegex && newFlag == NO)
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

    if (flags.shouldMatchRegex)
        regfree(&compiledRegex);

    result = regcomp(&compiledRegex, regexCString, REG_EXTENDED);
    if (result != 0) {
        char regex_error_buffer[256];

        if (regerror(result, &compiledRegex, regex_error_buffer, 256) > 0) {
            if (errorMessagePointer != NULL) {
                *errorMessagePointer = [NSString stringWithUTF8String:regex_error_buffer];
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
                NSLog(@"Error with regex matching string, %@", [NSString stringWithUTF8String:regex_error_buffer]);
        }

        return NO;
    }

    return YES;
}

@synthesize sdkRoot;

- (NSArray *)machOFiles;
{
    return machOFiles;
}

- (NSArray *)objcProcessors;
{
    return objcProcessors;
}

@synthesize targetArch;

- (BOOL)containsObjectiveCData;
{
    for (CDObjectiveCProcessor *processor in objcProcessors) {
        if ([processor hasObjectiveCData])
            return YES;
    }

    return NO;
}

- (BOOL)hasEncryptedFiles;
{
    for (CDMachOFile *machOFile in machOFiles) {
        if ([machOFile isEncrypted]) {
            return YES;
        }
    }

    return NO;
}

- (CDTypeController *)typeController;
{
    return typeController;
}

- (BOOL)loadFile:(CDFile *)aFile;
{
    CDMachOFile *aMachOFile;

    //NSLog(@"targetArch: (%08x, %08x)", targetArch.cputype, targetArch.cpusubtype);
    aMachOFile = [aFile machOFileWithArch:targetArch];
    //NSLog(@"aMachOFile: %@", aMachOFile);
    if (aMachOFile == nil) {
        fprintf(stderr, "Error: file doesn't contain the specified arch.\n\n");
        return NO;
    }

    // Set before processing recursively.  This was getting caught on CoreUI on 10.6
    assert([aMachOFile filename] != nil);
    [machOFiles addObject:aMachOFile];
    [machOFilesByID setObject:aMachOFile forKey:[aMachOFile filename]];

    if ([self shouldProcessRecursively]) {
        @try {
            for (CDLoadCommand *loadCommand in [aMachOFile loadCommands]) {
                if ([loadCommand isKindOfClass:[CDLCDylib class]]) {
                    CDLCDylib *aDylibCommand;

                    aDylibCommand = (CDLCDylib *)loadCommand;
                    if ([aDylibCommand cmd] == LC_LOAD_DYLIB) {
                        [searchPathState pushSearchPaths:[aMachOFile runPaths]];
                        [self machOFileWithID:[aDylibCommand path]]; // Loads as a side effect
                        [searchPathState popSearchPaths];
                    }
                }
            }
        }
        @catch (NSException *exception) {
            [aMachOFile release];
            return NO;
        }
    }

    return YES;
}

- (void)processObjectiveCData;
{
    for (CDMachOFile *machOFile in machOFiles) {
        CDObjectiveCProcessor *aProcessor;

        aProcessor = [[[machOFile processorClass] alloc] initWithMachOFile:machOFile];
        [aProcessor process];
        [objcProcessors addObject:aProcessor];
        [aProcessor release];
    }
}

// This visits everything segment processors, classes, categories.  It skips over modules.  Need something to visit modules so we can generate separate headers.
- (void)recursivelyVisit:(CDVisitor *)aVisitor;
{
    [aVisitor willBeginVisiting];

    if ([self containsObjectiveCData] || [self hasEncryptedFiles]) {
        for (CDObjectiveCProcessor *processor in objcProcessors) {
            [processor recursivelyVisit:aVisitor];
        }
    }

    [aVisitor didEndVisiting];
}

- (CDMachOFile *)machOFileWithID:(NSString *)anID;
{
    NSString *adjustedID = nil;
    CDMachOFile *aMachOFile;
    NSString *executablePathPrefix = @"@executable_path";
    NSString *rpathPrefix = @"@rpath";

    if ([anID hasPrefix:executablePathPrefix]) {
        adjustedID = [anID stringByReplacingOccurrencesOfString:executablePathPrefix withString:searchPathState.executablePath];
    } else if ([anID hasPrefix:rpathPrefix]) {
        //NSLog(@"Searching for %@ through run paths: %@", anID, [searchPathState searchPaths]);
        for (NSString *searchPath in [searchPathState searchPaths]) {
            NSString *str = [anID stringByReplacingOccurrencesOfString:rpathPrefix withString:searchPath];
            //NSLog(@"trying %@", str);
            if ([[NSFileManager defaultManager] fileExistsAtPath:str]) {
                adjustedID = str;
                //NSLog(@"Found it!");
                break;
            }
        }
        if (adjustedID == nil) {
            adjustedID = anID;
            //NSLog(@"Did not find it.");
        }
    } else if (sdkRoot != nil) {
        adjustedID = [sdkRoot stringByAppendingPathComponent:anID];
    } else {
        adjustedID = anID;
    }

    aMachOFile = [machOFilesByID objectForKey:adjustedID];
    if (aMachOFile == nil) {
        NSData *data;
        CDFile *aFile;

        data = [[NSData alloc] initWithContentsOfMappedFile:adjustedID];
        aFile = [CDFile fileWithData:data filename:adjustedID searchPathState:searchPathState];
        [data release];

        if (aFile == nil || [self loadFile:aFile] == NO)
            NSLog(@"Warning: Failed to load: %@", adjustedID);

        aMachOFile = [machOFilesByID objectForKey:adjustedID];
        if (aMachOFile == nil) {
            NSLog(@"Warning: Couldn't load MachOFile with ID: %@, adjustedID: %@", anID, adjustedID);
        }
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
    [resultString appendString:@" *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2010 by Steve Nygard.\n"];
    [resultString appendString:@" */\n\n"];

    if (sdkRoot != nil) {
        [resultString appendString:@"/*\n"];
        [resultString appendFormat:@" * SDK Root: %@\n", sdkRoot];
        [resultString appendString:@" */\n\n"];
    }
}

- (void)registerTypes;
{
    for (CDObjectiveCProcessor *processor in objcProcessors) {
        [processor registerTypesWithObject:typeController phase:0];
    }
    [typeController endPhase:0];

    [typeController workSomeMagic];
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
