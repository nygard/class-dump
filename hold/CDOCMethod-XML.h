// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "CDOCMethod.h"
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface CDOCMethod (XML)

- (void)addToXMLElement:(NSXMLElement *)xmlElement asClassMethod:(BOOL)asClassMethod classDump:(CDClassDump *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;

@end
