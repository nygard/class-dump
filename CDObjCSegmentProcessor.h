// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import <Foundation/NSObject.h>
#import "CDStructRegistrationProtocol.h"

@class NSMutableArray, NSMutableDictionary, NSMutableString, NSString;
@class CDClassDump2, CDMachOFile;

@interface CDObjCSegmentProcessor : NSObject
{
    CDMachOFile *machOFile;
    NSMutableArray *modules;
    NSMutableDictionary *protocolsByName;
}

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (void)process;

- (void)appendFormattedStringSortedByClass:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump;
- (void)registerStructsWithObject:(id <CDStructRegistration>)anObject;

- (NSString *)description;

@end
