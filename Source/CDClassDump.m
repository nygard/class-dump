// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDClassDump.h"

#import "CDFatArch.h"
#import "CDFatFile.h"
#import "CDLCDylib.h"
#import "CDMachOFile.h"
#import "CDObjectiveCProcessor.h"
#import "CDType.h"
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"
#import "CDVisitor.h"
#import "CDLCSegment.h"
#import "CDTypeController.h"
#import "CDSearchPathState.h"

@interface CDClassDump ()
- (CDMachOFile *)machOFileWithID:(NSString *)anID;
@end

#pragma mark -

@implementation CDClassDump
{
    CDSearchPathState *_searchPathState;
    
    BOOL _shouldProcessRecursively;
    BOOL _shouldSortClasses; // And categories, protocols
    BOOL _shouldSortClassesByInheritance; // And categories, protocols
    BOOL _shouldSortMethods;
    
    BOOL _shouldShowIvarOffsets;
    BOOL _shouldShowMethodAddresses;
    BOOL _shouldShowHeader;
    
    NSRegularExpression *_regularExpression;
    
    NSString *_sdkRoot;
    NSMutableArray *_machOFiles;
    NSMutableDictionary *_machOFilesByID;
    NSMutableArray *_objcProcessors;
    
    CDTypeController *_typeController;
    
    CDArch _targetArch;
}

- (id)init;
{
    if ((self = [super init])) {
        _searchPathState = [[CDSearchPathState alloc] init];
        _sdkRoot = nil;
        
        _machOFiles = [[NSMutableArray alloc] init];
        _machOFilesByID = [[NSMutableDictionary alloc] init];
        _objcProcessors = [[NSMutableArray alloc] init];
        
        _typeController = [[CDTypeController alloc] initWithClassDump:self];
        
        // These can be ppc, ppc7400, ppc64, i386, x86_64
        _targetArch.cputype = CPU_TYPE_ANY;
        _targetArch.cpusubtype = 0;
        
        _shouldShowHeader = YES;
    }

    return self;
}

#pragma mark - Regular expression handling

- (BOOL)shouldShowName:(NSString *)name;
{
    if (self.regularExpression != nil) {
        NSTextCheckingResult *firstMatch = [self.regularExpression firstMatchInString:name options:0 range:NSMakeRange(0, [name length])];
        return firstMatch != nil;
    }

    return YES;
}

#pragma mark -

- (BOOL)containsObjectiveCData;
{
    for (CDObjectiveCProcessor *processor in self.objcProcessors) {
        if ([processor hasObjectiveCData])
            return YES;
    }

    return NO;
}

- (BOOL)hasEncryptedFiles;
{
    for (CDMachOFile *machOFile in self.machOFiles) {
        if ([machOFile isEncrypted]) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)hasObjectiveCRuntimeInfo;
{
    return self.containsObjectiveCData || self.hasEncryptedFiles;
}

- (BOOL)loadFile:(CDFile *)file;
{
    //NSLog(@"targetArch: (%08x, %08x)", targetArch.cputype, targetArch.cpusubtype);
    CDMachOFile *aMachOFile = [file machOFileWithArch:_targetArch];
    //NSLog(@"aMachOFile: %@", aMachOFile);
    if (aMachOFile == nil) {
        fprintf(stderr, "Error: file doesn't contain the specified arch.\n\n");
        return NO;
    }

    // Set before processing recursively.  This was getting caught on CoreUI on 10.6
    assert([aMachOFile filename] != nil);
    [_machOFiles addObject:aMachOFile];
    [_machOFilesByID setObject:aMachOFile forKey:[aMachOFile filename]];

    if ([self shouldProcessRecursively]) {
        @try {
            for (CDLoadCommand *loadCommand in [aMachOFile loadCommands]) {
                if ([loadCommand isKindOfClass:[CDLCDylib class]]) {
                    CDLCDylib *aDylibCommand = (CDLCDylib *)loadCommand;
                    if ([aDylibCommand cmd] == LC_LOAD_DYLIB) {
                        [self.searchPathState pushSearchPaths:[aMachOFile runPaths]];
                        [self machOFileWithID:[aDylibCommand path]]; // Loads as a side effect
                        [self.searchPathState popSearchPaths];
                    }
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Caught exception: %@", exception);
            return NO;
        }
    }

    return YES;
}

#pragma mark -

- (void)processObjectiveCData;
{
    for (CDMachOFile *machOFile in self.machOFiles) {
        CDObjectiveCProcessor *aProcessor = [[[machOFile processorClass] alloc] initWithMachOFile:machOFile];
        [aProcessor process];
        [_objcProcessors addObject:aProcessor];
    }
}

// This visits everything segment processors, classes, categories.  It skips over modules.  Need something to visit modules so we can generate separate headers.
- (void)recursivelyVisit:(CDVisitor *)visitor;
{
    [visitor willBeginVisiting];

    for (CDObjectiveCProcessor *processor in self.objcProcessors) {
        [processor recursivelyVisit:visitor];
    }

    [visitor didEndVisiting];
}

- (CDMachOFile *)machOFileWithID:(NSString *)anID;
{
    NSString *adjustedID = nil;
    NSString *executablePathPrefix = @"@executable_path";
    NSString *rpathPrefix = @"@rpath";

    if ([anID hasPrefix:executablePathPrefix]) {
        adjustedID = [anID stringByReplacingOccurrencesOfString:executablePathPrefix withString:self.searchPathState.executablePath];
    } else if ([anID hasPrefix:rpathPrefix]) {
        //NSLog(@"Searching for %@ through run paths: %@", anID, [searchPathState searchPaths]);
        for (NSString *searchPath in [self.searchPathState searchPaths]) {
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
    } else if (self.sdkRoot != nil) {
        adjustedID = [self.sdkRoot stringByAppendingPathComponent:anID];
    } else {
        adjustedID = anID;
    }

    CDMachOFile *aMachOFile = [_machOFilesByID objectForKey:adjustedID];
    if (aMachOFile == nil) {
        NSData *data = [[NSData alloc] initWithContentsOfMappedFile:adjustedID];
        CDFile *aFile = [CDFile fileWithData:data filename:adjustedID searchPathState:self.searchPathState];

        if (aFile == nil || [self loadFile:aFile] == NO)
            NSLog(@"Warning: Failed to load: %@", adjustedID);

        aMachOFile = [_machOFilesByID objectForKey:adjustedID];
        if (aMachOFile == nil) {
            NSLog(@"Warning: Couldn't load MachOFile with ID: %@, adjustedID: %@", anID, adjustedID);
        }
    }

    return aMachOFile;
}

- (void)appendHeaderToString:(NSMutableString *)resultString;
{
    // Since this changes each version, for regression testing it'll be better to be able to not show it.
    if (self.shouldShowHeader == NO)
        return;

    [resultString appendString:@"/*\n"];
    [resultString appendFormat:@" *     Generated by class-dump %s.\n", CLASS_DUMP_VERSION];
    [resultString appendString:@" *\n"];
    [resultString appendString:@" *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2012 by Steve Nygard.\n"];
    [resultString appendString:@" */\n\n"];

    if (self.sdkRoot != nil) {
        [resultString appendString:@"/*\n"];
        [resultString appendFormat:@" * SDK Root: %@\n", self.sdkRoot];
        [resultString appendString:@" */\n\n"];
    }
}

- (void)registerTypes;
{
    for (CDObjectiveCProcessor *processor in self.objcProcessors) {
        [processor registerTypesWithObject:self.typeController phase:0];
    }
    [self.typeController endPhase:0];

    [self.typeController workSomeMagic];
}

- (void)showHeader;
{
    if ([self.machOFiles count] > 0) {
        [[[self.machOFiles lastObject] headerString:YES] print];
    }
}

- (void)showLoadCommands;
{
    if ([self.machOFiles count] > 0) {
        [[[self.machOFiles lastObject] loadCommandString:YES] print];
    }
}

@end
