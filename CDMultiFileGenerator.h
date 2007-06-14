// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import <Foundation/Foundation.h>

@class CDClassDump, CDOCSymtab;

@interface CDMultiFileGenerator : NSObject
{
    CDClassDump *classDump;
    NSString *outputPath;
    NSMutableDictionary *frameworkNamesByClassName;
}

- (id)init;
- (void)dealloc;

- (CDClassDump *)classDump;
- (void)setClassDump:(CDClassDump *)newClassDump;

- (NSString *)outputPath;
- (void)setOutputPath:(NSString *)newOutputPath;

- (void)createOutputPathIfNecessary;

- (void)buildClassFrameworks;
- (NSString *)frameworkForClassName:(NSString *)aClassName;

- (void)appendImportForClassName:(NSString *)aClassName toString:(NSMutableString *)resultString;

- (void)generateStructureHeader;

- (void)generateOutput;

- (void)generateSeparateHeadersForSymtab:(CDOCSymtab *)aSymtab;

@end
