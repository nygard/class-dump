//
// $Id: CDClassDump.h,v 1.40 2004/02/02 22:19:00 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>

#import "CDStructureRegistrationProtocol.h"

#define CLASS_DUMP_VERSION @"3.0 alpha"

@class NSMutableArray, NSMutableDictionary, NSMutableSet, NSMutableString, NSString;
@class CDDylibCommand, CDMachOFile;
@class CDStructureTable, CDSymbolReferences, CDType, CDTypeFormatter;

@interface CDClassDump2 : NSObject <CDStructureRegistration>
{
    NSString *executablePath;

    BOOL shouldProcessRecursively;
    BOOL shouldGenerateSeparateHeaders;
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
