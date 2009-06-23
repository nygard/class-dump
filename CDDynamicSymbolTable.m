// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDDynamicSymbolTable.h"

#include <mach-o/loader.h>
#include <mach-o/swap.h>
#import <Foundation/Foundation.h>
#import "CDFatFile.h"
#import "CDMachOFile.h"

@implementation CDDynamicSymbolTable

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    dysymtab.cmd = [cursor readInt32];
    dysymtab.cmdsize = [cursor readInt32];

    dysymtab.ilocalsym = [cursor readInt32];
    dysymtab.nlocalsym = [cursor readInt32];
    dysymtab.iextdefsym = [cursor readInt32];
    dysymtab.nextdefsym = [cursor readInt32];
    dysymtab.iundefsym = [cursor readInt32];
    dysymtab.nundefsym = [cursor readInt32];
    dysymtab.tocoff = [cursor readInt32];
    dysymtab.ntoc = [cursor readInt32];
    dysymtab.modtaboff = [cursor readInt32];
    dysymtab.nmodtab = [cursor readInt32];
    dysymtab.extrefsymoff = [cursor readInt32];
    dysymtab.nextrefsyms = [cursor readInt32];
    dysymtab.indirectsymoff = [cursor readInt32];
    dysymtab.nindirectsyms = [cursor readInt32];
    dysymtab.extreloff = [cursor readInt32];
    dysymtab.nextrel = [cursor readInt32];
    dysymtab.locreloff = [cursor readInt32];
    dysymtab.nlocrel = [cursor readInt32];
#if 0
    NSLog(@"ilocalsym:      0x%08x  %d", dysymtab.ilocalsym, dysymtab.ilocalsym);
    NSLog(@"nlocalsym:      0x%08x  %d", dysymtab.nlocalsym, dysymtab.nlocalsym);
    NSLog(@"iextdefsym:     0x%08x  %d", dysymtab.iextdefsym, dysymtab.iextdefsym);
    NSLog(@"nextdefsym:     0x%08x  %d", dysymtab.nextdefsym, dysymtab.nextdefsym);
    NSLog(@"iundefsym:      0x%08x  %d", dysymtab.iundefsym, dysymtab.iundefsym);
    NSLog(@"nundefsym:      0x%08x  %d", dysymtab.nundefsym, dysymtab.nundefsym);

    NSLog(@"tocoff:         0x%08x  %d", dysymtab.tocoff, dysymtab.tocoff);
    NSLog(@"ntoc:           0x%08x  %d", dysymtab.ntoc, dysymtab.ntoc);
    NSLog(@"modtaboff:      0x%08x  %d", dysymtab.modtaboff, dysymtab.modtaboff);
    NSLog(@"nmodtab:        0x%08x  %d", dysymtab.nmodtab, dysymtab.nmodtab);

    NSLog(@"extrefsymoff:   0x%08x  %d", dysymtab.extrefsymoff, dysymtab.extrefsymoff);
    NSLog(@"nextrefsyms:    0x%08x  %d", dysymtab.nextrefsyms, dysymtab.nextrefsyms);
    NSLog(@"indirectsymoff: 0x%08x  %d", dysymtab.indirectsymoff, dysymtab.indirectsymoff);
    NSLog(@"nindirectsyms:  0x%08x  %d", dysymtab.nindirectsyms, dysymtab.nindirectsyms);

    NSLog(@"extreloff:      0x%08x  %d", dysymtab.extreloff, dysymtab.extreloff);
    NSLog(@"nextrel:        0x%08x  %d", dysymtab.nextrel, dysymtab.nextrel);
    NSLog(@"locreloff:      0x%08x  %d", dysymtab.locreloff, dysymtab.locreloff);
    NSLog(@"nlocrel:        0x%08x  %d", dysymtab.nlocrel, dysymtab.nlocrel);
#endif
    return self;
}

- (uint32_t)cmd;
{
    return dysymtab.cmd;
}

- (uint32_t)cmdsize;
{
    return dysymtab.cmdsize;
}

@end
