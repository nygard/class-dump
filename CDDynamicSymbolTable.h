//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2004 Steve Nygard.  All rights reserved.

#import "CDLoadCommand.h"

@interface CDDynamicSymbolTable : CDLoadCommand
{
    unsigned long ilocalsym;
    unsigned long nlocalsym;
    unsigned long iextdefsym;
    unsigned long nextdefsym;
    unsigned long iundefsym;
    unsigned long nundefsym;

    unsigned long tocoff;
    unsigned long ntoc;

    unsigned long modtaboff;
    unsigned long nmodtab;

    unsigned long extrefsymoff;
    unsigned long nextrefsyms;

    unsigned long indirectsymoff;
    unsigned long nindirectsyms;

    unsigned long extreloff;
    unsigned long nextrel;

    unsigned long locreloff;
    unsigned long nlocrel;
}

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;

@end
