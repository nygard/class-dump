//
// $Id: CDClassDump.h,v 1.23 2004/01/07 18:14:18 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>
#import "CDStructRegistrationProtocol.h"

@class NSMutableArray, NSMutableDictionary, NSMutableString, NSString;
@class CDDylibCommand, CDMachOFile;
@class CDType, CDTypeFormatter;

@interface CDClassDump2 : NSObject <CDStructRegistration>
{
    NSMutableDictionary *machOFilesByID;
    NSMutableArray *objCSegmentProcessors;
    BOOL shouldProcessRecursively;

    // Can you say "just hacking out code"?
    NSMutableDictionary *structCountsByType;
    NSMutableDictionary *structsByName;
    NSMutableDictionary *anonymousStructNames;
    NSMutableDictionary *anonymousStructsByType;
    NSMutableDictionary *anonymousRemapping;

    int anonymousStructCounter;

    CDTypeFormatter *ivarTypeFormatter;
    CDTypeFormatter *methodTypeFormatter;
    CDTypeFormatter *structDeclarationTypeFormatter;
}

- (id)init;
- (void)dealloc;

- (BOOL)shouldProcessRecursively;
- (void)setShouldProcessRecursively:(BOOL)newFlag;

- (CDTypeFormatter *)ivarTypeFormatter;
- (CDTypeFormatter *)methodTypeFormatter;
- (CDTypeFormatter *)structDeclarationTypeFormatter;

- (void)processFilename:(NSString *)aFilename;

- (void)processIsomorphicStructs;
- (void)logStructCounts;
- (void)logAnonymousRemappings;
- (void)logNamedStructs;
- (void)logAnonymousStructs;

- (void)doSomething;

- (CDMachOFile *)machOFileWithID:(NSString *)anID;

- (void)machOFile:(CDMachOFile *)aMachOFile loadDylib:(CDDylibCommand *)aDylibCommand;

- (void)appendHeaderToString:(NSMutableString *)resultString;
- (void)appendNamedStructsToString:(NSMutableString *)resultString;
- (void)appendTypedefsToString:(NSMutableString *)resultString;

- (void)registerStruct:(CDType *)structType name:(NSString *)aName countReferences:(BOOL)shouldCountReferences;
- (NSString *)typeFormatter:(CDTypeFormatter *)aFormatter typedefNameForStruct:(NSString *)structTypeString;

@end
