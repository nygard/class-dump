//
// $Id: CDSymbolReferences.h,v 1.2 2004/02/03 22:18:37 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>

@class NSArray, NSMutableSet, NSMutableString, NSString;

@interface CDSymbolReferences : NSObject
{
    NSMutableSet *classes;
    NSMutableSet *protocols;
}

- (id)init;
- (void)dealloc;

- (NSArray *)classes;
- (void)addClassName:(NSString *)aClassName;
- (void)removeClassName:(NSString *)aClassName;

- (NSArray *)protocols;
- (void)addProtocolName:(NSString *)aProtocolName;
- (void)addProtocolNamesFromArray:(NSArray *)protocolNames;

- (NSString *)description;

- (void)_appendToString:(NSMutableString *)resultString;
- (NSString *)referenceString;

@end
