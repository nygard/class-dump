// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "CDOCIvar.h"
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface CDOCIvar (XML)

- (void)addToXMLElement:(NSXMLElement *)xmlElement classDump:(CDClassDump *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;

@end
