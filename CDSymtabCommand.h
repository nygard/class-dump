//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2004 Steve Nygard.  All rights reserved.

#import "CDLoadCommand.h"

@interface CDSymtabCommand : CDLoadCommand
{
    const struct symtab_command *symtabCommand;
}

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;

- (void)_process;

@end
