// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import <Foundation/NSObject.h>
#import "CDStructRegistrationProtocol.h"

@class NSMutableArray, NSMutableDictionary, NSMutableString, NSString;
@class CDClassDump2, CDMachOFile;

@interface CDObjCSegmentProcessor : NSObject
{
    CDClassDump2 *nonretainedClassDumper;

    CDMachOFile *machOFile;
    NSMutableArray *modules;
    NSMutableDictionary *protocolsByName;
}

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (CDClassDump2 *)classDumper;
- (void)setClassDumper:(CDClassDump2 *)newClassDumper;

- (void)process;

- (NSString *)formattedStringByModule;
- (void)appendFormattedStringSortedByClass:(NSMutableString *)resultString;
- (void)registerStructsWithObject:(id <CDStructRegistration>)anObject;

- (NSString *)description;

@end
