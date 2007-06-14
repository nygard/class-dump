//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import <Foundation/NSObject.h>
#import "CDStructureRegistrationProtocol.h"

@class NSArray, NSMutableArray, NSMutableDictionary, NSMutableString, NSString;
@class CDClassDump, CDMachOFile;
@class CDVisitor;

@interface CDObjCSegmentProcessor : NSObject
{
    CDMachOFile *machOFile;
    NSMutableArray *modules;
    NSMutableDictionary *protocolsByName;
}

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (CDMachOFile *)machOFile;

- (NSArray *)modules;

- (BOOL)hasModules;
- (void)process;

- (void)addToXMLElement:(NSXMLElement *)xmlElement classDump:(CDClassDump *)aClassDump;
- (void)appendFormattedString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump;
- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;

- (NSString *)description;

- (void)registerClassesWithObject:(NSMutableDictionary *)aDictionary;
- (void)generateSeparateHeadersClassDump:(CDClassDump *)aClassDump;

- (void)find:(NSString *)str classDump:(CDClassDump *)aClassDump appendResultToString:(NSMutableString *)resultString;

- (void)recursivelyVisit:(CDVisitor *)aVisitor;

@end
