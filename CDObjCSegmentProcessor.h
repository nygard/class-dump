//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2006  Steve Nygard

#import <Foundation/NSObject.h>
#import "CDStructureRegistrationProtocol.h"

@class NSArray, NSMutableArray, NSMutableDictionary, NSMutableString, NSString;
@class CDClassDump, CDMachOFile;

@interface CDObjCSegmentProcessor : NSObject
{
    CDMachOFile *machOFile;
    NSMutableArray *modules;
    NSMutableDictionary *protocolsByName;
}

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (BOOL)hasModules;
- (void)process;

- (void)addToXMLElement:(NSXMLElement *)xmlElement classDump:(CDClassDump *)aClassDump;
- (void)appendFormattedString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump;
- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;

- (NSString *)description;

- (void)registerClassesWithObject:(NSMutableDictionary *)aDictionary;
- (void)generateSeparateHeadersClassDump:(CDClassDump *)aClassDump;

@end
