//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2004 Steve Nygard.  All rights reserved.

#import "CDLoadCommand.h"

@interface CDDynamicSymbolTable : CDLoadCommand
{
    struct dysymtab_command dysymtab;
}

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;

@end
