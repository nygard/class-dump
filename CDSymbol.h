//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2006  Steve Nygard

#import <Foundation/NSObject.h>

#include <mach-o/nlist.h>

@class CDMachOFile;

@interface CDSymbol : NSObject
{
    const struct nlist *nlist;
    NSString *name;
}

- (id)initWithPointer:(const void *)ptr symtab:(const struct symtab_command *)symtabCommand machOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (long)strx;
- (unsigned char)type;
- (unsigned char)section;
- (short)desc;
- (unsigned long)value;

- (NSString *)name;
- (NSString *)description;

@end
