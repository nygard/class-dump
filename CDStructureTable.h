//
// $Id: CDStructureTable.h,v 1.1 2004/01/08 04:44:20 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>

@class NSMutableDictionary, NSMutableSet;

@interface CDStructureTable : NSObject
{
    NSMutableDictionary *structuresByName;

    NSMutableDictionary *anonymousStructureCountsByType;
    NSMutableDictionary *anonymousStructuresByType;
    NSMutableDictionary *anonymousStructureNamesByType;

    NSMutableDictionary *replacementTypes;
    NSMutableSet *forcedTypedefs;
}

- (id)init;
- (void)dealloc;

@end
