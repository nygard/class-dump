//
// $Id: CDSymbolReferences.h,v 1.1 2004/02/02 21:46:22 nygard Exp $
//

//  This file is part of APPNAME, SHORT DESCRIPTION
//  Copyright (C) 2004 Steve Nygard.  All rights reserved.

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
