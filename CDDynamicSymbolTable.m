//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2004 Steve Nygard.  All rights reserved.

#import "CDDynamicSymbolTable.h"

#include <mach-o/loader.h>
#import <Foundation/Foundation.h>

@implementation CDDynamicSymbolTable

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
{
    const struct dysymtab_command *dysymtab = ptr;

    if ([super initWithPointer:ptr machOFile:aMachOFile] == nil)
        return nil;

    ilocalsym = dysymtab->ilocalsym;
    nlocalsym = dysymtab->nlocalsym;
    iextdefsym = dysymtab->iextdefsym;
    nextdefsym = dysymtab->nextdefsym;
    iundefsym = dysymtab->iundefsym;
    nundefsym = dysymtab->nundefsym;

    tocoff= dysymtab->tocoff;
    ntoc = dysymtab->ntoc;

    modtaboff = dysymtab->modtaboff;
    nmodtab = dysymtab->nmodtab;

    extrefsymoff = dysymtab->extrefsymoff;
    nextrefsyms = dysymtab->nextrefsyms;

    indirectsymoff = dysymtab->indirectsymoff;
    nindirectsyms = dysymtab->nindirectsyms;

    extreloff = dysymtab->extreloff;
    nextrel = dysymtab->nextrel;

    locreloff = dysymtab->locreloff;
    nlocrel = dysymtab->nlocrel;

    NSLog(@"ilocalsym:      0x%08x  %d", ilocalsym, ilocalsym);
    NSLog(@"nlocalsym:      0x%08x  %d", nlocalsym, nlocalsym);
    NSLog(@"iextdefsym:     0x%08x  %d", iextdefsym, iextdefsym);
    NSLog(@"nextdefsym:     0x%08x  %d", nextdefsym, nextdefsym);
    NSLog(@"iundefsym:      0x%08x  %d", iundefsym, iundefsym);
    NSLog(@"nundefsym:      0x%08x  %d", nundefsym, nundefsym);

    NSLog(@"tocoff:         0x%08x  %d", tocoff, tocoff);
    NSLog(@"ntoc:           0x%08x  %d", ntoc, ntoc);
    NSLog(@"modtaboff:      0x%08x  %d", modtaboff, modtaboff);
    NSLog(@"nmodtab:        0x%08x  %d", nmodtab, nmodtab);

    NSLog(@"extrefsymoff:   0x%08x  %d", extrefsymoff, extrefsymoff);
    NSLog(@"nextrefsyms:    0x%08x  %d", nextrefsyms, nextrefsyms);
    NSLog(@"indirectsymoff: 0x%08x  %d", indirectsymoff, indirectsymoff);
    NSLog(@"nindirectsyms:  0x%08x  %d", nindirectsyms, nindirectsyms);

    NSLog(@"extreloff:      0x%08x  %d", extreloff, extreloff);
    NSLog(@"nextrel:        0x%08x  %d", nextrel, nextrel);
    NSLog(@"locreloff:      0x%08x  %d", locreloff, locreloff);
    NSLog(@"nlocrel:        0x%08x  %d", nlocrel, nlocrel);

    return self;
}

@end
