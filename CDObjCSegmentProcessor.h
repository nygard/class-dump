//
// $Id: CDObjCSegmentProcessor.h,v 1.7 2004/01/06 01:51:55 nygard Exp $
//

//  This file is part of class-dump, a utility for exmaing the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

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
