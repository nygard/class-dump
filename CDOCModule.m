//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDOCModule.h"

#import <Foundation/Foundation.h>
#import "CDObjCSegmentProcessor.h"
#import "CDOCSymtab.h"

@implementation CDOCModule

- (id)init;
{
    if ([super init] == nil)
        return nil;

    version = 0;
    name = nil;
    symtab = nil;

    return self;
}

- (void)dealloc;
{
    [name release];
    [symtab release];

    [super dealloc];
}

- (unsigned long)version;
{
    return version;
}

- (void)setVersion:(unsigned long)aVersion;
{
    version = aVersion;
}

- (NSString *)name;
{
    return name;
}

- (void)setName:(NSString *)newName;
{
    if (newName == name)
        return;

    [name release];
    name = [newName retain];
}

- (CDOCSymtab *)symtab;
{
    return symtab;
}

- (void)setSymtab:(CDOCSymtab *)newSymtab;
{
    if (newSymtab == symtab)
        return;

    [symtab release];
    symtab = [newSymtab retain];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, version: %d, symtab: %@", NSStringFromClass([self class]), name, version, symtab];
}

- (NSString *)formattedString;
{
    return [NSString stringWithFormat:@"/*\n * %@\n */\n", name];
}

@end
