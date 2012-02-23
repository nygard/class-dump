// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDTextClassDumpVisitor.h"

@class CDSymbolReferences;

@interface CDMultiFileVisitor : CDTextClassDumpVisitor
{
    NSString *outputPath;
    NSUInteger referenceIndex;
}

@property (retain) NSString *outputPath;

- (void)createOutputPathIfNecessary;

- (void)buildClassFrameworks;

- (void)generateStructureHeader;

@end
