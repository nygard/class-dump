// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

#include <sys/types.h>
#include <regex.h>
#import "CDFile.h" // For CDArch

#ifdef __LP64__
#define CLASS_DUMP_BASE_VERSION "3.3.3 (64 bit)"
#else
#define CLASS_DUMP_BASE_VERSION "3.3.3 (32 bit)"
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

    struct {
        unsigned int shouldProcessRecursively:1;
        unsigned int shouldSortClasses:1; // And categories, protocols
        unsigned int shouldSortClassesByInheritance:1; // And categories, protocols
        unsigned int shouldSortMethods:1;

        unsigned int shouldShowIvarOffsets:1;
        unsigned int shouldShowMethodAddresses:1;
        unsigned int shouldMatchRegex:1;
        unsigned int shouldShowHeader:1;
    } flags;

    regex_t compiledRegex;

    NSString *sdkRoot;
    NSMutableArray *machOFiles;
    NSMutableDictionary *machOFilesByID;
    NSMutableArray *objcProcessors;

    CDTypeController *typeController;

    CDArch targetArch;
}

- (id)init;
- (void)dealloc;

@property(readonly) CDSearchPathState *searchPathState;
@property BOOL shouldProcessRecursively;
@property BOOL shouldSortClasses;
@property BOOL shouldSortClassesByInheritance;
@property BOOL shouldSortMethods;
@property BOOL shouldShowIvarOffsets;
@property BOOL shouldShowMethodAddresses;
@property BOOL shouldMatchRegex;
@property BOOL shouldShowHeader;

- (BOOL)setRegex:(char *)regexCString errorMessage:(NSString **)errorMessagePointer;
- (BOOL)regexMatchesString:(NSString *)aString;

@property(retain) NSString *sdkRoot;

- (NSArray *)machOFiles;
- (NSArray *)objcProcessors;

@property CDArch targetArch;

- (BOOL)containsObjectiveCData;
- (BOOL)hasEncryptedFiles;

- (CDTypeController *)typeController;

- (BOOL)loadFile:(CDFile *)aFile;
- (void)processObjectiveCData;

- (void)recursivelyVisit:(CDVisitor *)aVisitor;

- (CDMachOFile *)machOFileWithID:(NSString *)anID;

- (void)appendHeaderToString:(NSMutableString *)resultString;

- (void)registerTypes;

- (void)showHeader;
- (void)showLoadCommands;

@end
