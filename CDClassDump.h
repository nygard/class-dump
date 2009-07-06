// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import <Foundation/Foundation.h>

#include <sys/types.h>
#include <regex.h>
#import "CDStructureRegistrationProtocol.h"
#import "CDFile.h" // For CDArch

#ifdef __LP64__
#define CLASS_DUMP_BASE_VERSION "3.2.1 (64 bit)"
#else
#define CLASS_DUMP_BASE_VERSION "3.2.1 (32 bit)"
#endif

#ifdef DEBUG
#define CLASS_DUMP_VERSION CLASS_DUMP_BASE_VERSION " (Debug version compiled " __DATE__ " " __TIME__ ")"
#else
#define CLASS_DUMP_VERSION CLASS_DUMP_BASE_VERSION
#endif

@class CDLCDylib, CDFile, CDMachOFile;
@class CDStructureTable, CDSymbolReferences, CDType, CDTypeFormatter;
@class CDVisitor;

@interface CDClassDump : NSObject <CDStructureRegistration>
{
    NSString *executablePath;

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

    NSMutableArray *machOFiles;
    NSMutableDictionary *machOFilesByID;
    NSMutableArray *objcProcessors;

    CDStructureTable *structureTable;
    CDStructureTable *unionTable;

    CDTypeFormatter *ivarTypeFormatter;
    CDTypeFormatter *methodTypeFormatter;
    CDTypeFormatter *propertyTypeFormatter;
    CDTypeFormatter *structDeclarationTypeFormatter;

    CDArch targetArch;
}

- (id)init;
- (void)dealloc;

- (NSString *)executablePath;
- (void)setExecutablePath:(NSString *)newPath;

- (BOOL)shouldProcessRecursively;
- (void)setShouldProcessRecursively:(BOOL)newFlag;

- (BOOL)shouldSortClasses;
- (void)setShouldSortClasses:(BOOL)newFlag;

- (BOOL)shouldSortClassesByInheritance;
- (void)setShouldSortClassesByInheritance:(BOOL)newFlag;

- (BOOL)shouldSortMethods;
- (void)setShouldSortMethods:(BOOL)newFlag;

- (BOOL)shouldShowIvarOffsets;
- (void)setShouldShowIvarOffsets:(BOOL)newFlag;

- (BOOL)shouldShowMethodAddresses;
- (void)setShouldShowMethodAddresses:(BOOL)newFlag;

- (BOOL)shouldMatchRegex;
- (void)setShouldMatchRegex:(BOOL)newFlag;

- (BOOL)shouldShowHeader;
- (void)setShouldShowHeader:(BOOL)newFlag;

- (BOOL)setRegex:(char *)regexCString errorMessage:(NSString **)errorMessagePointer;
- (BOOL)regexMatchesString:(NSString *)aString;

- (NSArray *)machOFiles;
- (NSArray *)objcProcessors;

- (CDArch)targetArch;
- (void)setTargetArch:(CDArch)newArch;

- (BOOL)containsObjectiveCData;
- (CDStructureTable *)structureTable;
- (CDStructureTable *)unionTable;

- (CDTypeFormatter *)ivarTypeFormatter;
- (CDTypeFormatter *)methodTypeFormatter;
- (CDTypeFormatter *)propertyTypeFormatter;
- (CDTypeFormatter *)structDeclarationTypeFormatter;

- (BOOL)_loadFilename:(NSString *)aFilename;
- (BOOL)loadFile:(CDFile *)aFile;
- (void)processObjectiveCData;

- (void)recursivelyVisit:(CDVisitor *)aVisitor;

- (void)registerStuff;

- (void)logInfo;
- (void)appendStructuresToString:(NSMutableString *)resultString symbolReferences:(CDSymbolReferences *)symbolReferences;

- (CDMachOFile *)machOFileWithID:(NSString *)anID;

- (void)appendHeaderToString:(NSMutableString *)resultString;

- (CDType *)typeFormatter:(CDTypeFormatter *)aFormatter replacementForType:(CDType *)aType;
- (NSString *)typeFormatter:(CDTypeFormatter *)aFormatter typedefNameForStruct:(CDType *)structType level:(int)level;

- (void)registerPhase:(int)phase;
- (void)endPhase:(int)phase;

- (void)phase1RegisterStructure:(CDType *)aStructure;
- (BOOL)phase2RegisterStructure:(CDType *)aStructure usedInMethod:(BOOL)isUsedInMethod countReferences:(BOOL)shouldCountReferences;

- (void)generateMemberNames;

- (void)showHeader;
- (void)showLoadCommands;

@end
