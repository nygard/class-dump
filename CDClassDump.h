// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import <Foundation/Foundation.h>

#include <sys/types.h>
#include <regex.h>
#import "CDFile.h" // For CDArch

#ifdef __LP64__
#define CLASS_DUMP_BASE_VERSION "3.3.4 (64 bit)"
#else
#define CLASS_DUMP_BASE_VERSION "3.3.4 (32 bit)"
#endif

#ifdef DEBUG
#define CLASS_DUMP_VERSION CLASS_DUMP_BASE_VERSION " (Debug version compiled " __DATE__ " " __TIME__ ")"
#else
#define CLASS_DUMP_VERSION CLASS_DUMP_BASE_VERSION
#endif

@class CDLCDylib, CDFile, CDMachOFile;
@class CDSymbolReferences, CDType, CDTypeController, CDTypeFormatter;
@class CDVisitor;
@class CDSearchPathState;

@interface CDClassDump : NSObject
{
    CDSearchPathState *searchPathState;

    BOOL shouldProcessRecursively;
    BOOL shouldSortClasses; // And categories, protocols
    BOOL shouldSortClassesByInheritance; // And categories, protocols
    BOOL shouldSortMethods;
    
    BOOL shouldShowIvarOffsets;
    BOOL shouldShowMethodAddresses;
    BOOL shouldShowHeader;

    BOOL shouldMatchRegex;
    regex_t compiledRegex;

    NSString *sdkRoot;
    NSMutableArray *machOFiles;
    NSMutableDictionary *machOFilesByID;
    NSMutableArray *objcProcessors;

    CDTypeController *typeController;

    CDArch targetArch;
}

@property (readonly) CDSearchPathState *searchPathState;

@property (assign) BOOL shouldProcessRecursively;
@property (assign) BOOL shouldSortClasses;
@property (assign) BOOL shouldSortClassesByInheritance;
@property (assign) BOOL shouldSortMethods;
@property (assign) BOOL shouldShowIvarOffsets;
@property (assign) BOOL shouldShowMethodAddresses;
@property (assign) BOOL shouldShowHeader;

@property (nonatomic, assign) BOOL shouldMatchRegex;
- (BOOL)setRegex:(char *)regexCString errorMessage:(NSString **)errorMessagePointer;
- (BOOL)regexMatchesString:(NSString *)aString;

@property (retain) NSString *sdkRoot;

@property (readonly) NSArray *machOFiles;
@property (readonly) NSArray *objcProcessors;

@property (assign) CDArch targetArch;

@property (readonly) BOOL containsObjectiveCData;
@property (readonly) BOOL hasEncryptedFiles;
@property (readonly) BOOL hasObjectiveCRuntimeInfo;

@property (readonly) CDTypeController *typeController;

- (BOOL)loadFile:(CDFile *)aFile;
- (void)processObjectiveCData;

- (void)recursivelyVisit:(CDVisitor *)aVisitor;

- (CDMachOFile *)machOFileWithID:(NSString *)anID;

- (void)appendHeaderToString:(NSMutableString *)resultString;

- (void)registerTypes;

- (void)showHeader;
- (void)showLoadCommands;

@end
