//
// $Id: CDClassDump.h,v 1.43 2004/02/03 00:35:48 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>

#include <sys/types.h>
#include <regex.h>
#import "CDStructureRegistrationProtocol.h"

#define CLASS_DUMP_VERSION @"3.0 alpha"

@class NSMutableArray, NSMutableDictionary, NSMutableSet, NSMutableString, NSString;
@class CDDylibCommand, CDMachOFile;
@class CDStructureTable, CDSymbolReferences, CDType, CDTypeFormatter;

@interface CDClassDump2 : NSObject <CDStructureRegistration>
{
    NSString *executablePath;

    struct {
        unsigned int shouldProcessRecursively:1;
        unsigned int shouldGenerateSeparateHeaders:1;
        unsigned int shouldSortClasses:1; // And categories, protocols
        unsigned int shouldSortMethods:1;

        unsigned int shouldShowIvarOffsets:1;
        unsigned int shouldShowMethodAddresses:1;
        unsigned int shouldExpandProtocols:1;
        unsigned int shouldMatchRegex:1;
    } flags;

    regex_t compiledRegex;
    NSString *outputPath;

    NSMutableDictionary *machOFilesByID;
    NSMutableArray *objCSegmentProcessors;

    CDStructureTable *structureTable;
    CDStructureTable *unionTable;

    CDTypeFormatter *ivarTypeFormatter;
    CDTypeFormatter *methodTypeFormatter;
    CDTypeFormatter *structDeclarationTypeFormatter;

    NSMutableDictionary *frameworkNamesByClassName;
}

+ (void)initialize;
+ (BOOL)isWrapperAtPath:(NSString *)path;
+ (NSString *)pathToMainFileOfWrapper:(NSString *)wrapperPath;
+ (NSString *)adjustUserSuppliedPath:(NSString *)path;

- (id)init;
- (void)dealloc;

- (NSString *)executablePath;
- (void)setExecutablePath:(NSString *)newPath;

- (BOOL)shouldProcessRecursively;
- (void)setShouldProcessRecursively:(BOOL)newFlag;

- (BOOL)shouldGenerateSeparateHeaders;
- (void)setShouldGenerateSeparateHeaders:(BOOL)newFlag;

- (BOOL)shouldSortClasses;
- (void)setShouldSortClasses:(BOOL)newFlag;

- (BOOL)shouldSortMethods;
- (void)setShouldSortMethods:(BOOL)newFlag;

- (BOOL)shouldShowIvarOffsets;
- (void)setShouldShowIvarOffsets:(BOOL)newFlag;

- (BOOL)shouldShowMethodAddresses;
- (void)setShouldShowMethodAddresses:(BOOL)newFlag;

- (BOOL)shouldExpandProtocols;
- (void)setShouldExpandProtocols:(BOOL)newFlag;

- (BOOL)shouldMatchRegex;
- (void)setShouldMatchRegex:(BOOL)newFlag;

- (BOOL)setRegex:(char *)regexCString errorMessage:(NSString **)errorMessagePointer;

- (NSString *)outputPath;
- (void)setOutputPath:(NSString *)aPath;

- (CDStructureTable *)structureTable;
- (CDStructureTable *)unionTable;

- (CDTypeFormatter *)ivarTypeFormatter;
- (CDTypeFormatter *)methodTypeFormatter;
- (CDTypeFormatter *)structDeclarationTypeFormatter;

- (void)processFilename:(NSString *)aFilename;
- (void)_processFilename:(NSString *)aFilename;

- (void)doSomething;
- (void)generateToStandardOut;
- (void)generateSeparateHeaders;
- (void)generateStructureHeader;

- (void)logInfo;
- (void)appendStructuresToString:(NSMutableString *)resultString symbolReferences:(CDSymbolReferences *)symbolReferences;

- (CDMachOFile *)machOFileWithID:(NSString *)anID;

- (void)machOFile:(CDMachOFile *)aMachOFile loadDylib:(CDDylibCommand *)aDylibCommand;

- (void)appendHeaderToString:(NSMutableString *)resultString;

- (CDType *)typeFormatter:(CDTypeFormatter *)aFormatter replacementForType:(CDType *)aType;
- (NSString *)typeFormatter:(CDTypeFormatter *)aFormatter typedefNameForStruct:(CDType *)structType level:(int)level;

- (void)registerPhase:(int)phase;
- (void)endPhase:(int)phase;

- (void)phase1RegisterStructure:(CDType *)aStructure;
- (BOOL)phase2RegisterStructure:(CDType *)aStructure usedInMethod:(BOOL)isUsedInMethod countReferences:(BOOL)shouldCountReferences;

- (void)generateMemberNames;

- (void)buildClassFrameworks;
- (NSString *)frameworkForClassName:(NSString *)aClassName;

- (void)appendImportForClassName:(NSString *)aClassName toString:(NSMutableString *)resultString;

@end
