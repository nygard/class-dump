//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDSegmentCommand.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>
#import "CDSection.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDSegmentCommand.m,v 1.4 2004/01/06 02:31:43 nygard Exp $");

@implementation CDSegmentCommand

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
{
    char buf[17];

    if ([super initWithPointer:ptr machOFile:aMachOFile] == nil)
        return nil;

    segmentCommand = ptr;
    memcpy(buf, segmentCommand->segname, 16);
    buf[16] = 0;
    name = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
    // Is segmentCommand->segname always going to be NULL terminated?
    //name = [[NSString alloc] initWithBytes:segmentCommand->segname length:strlen(segmentCommand->segname) encoding:NSASCIIStringEncoding];
    //contents = nil;

    [self _processSections];

#if 0
    if ([@"__OBJC" isEqual:name]) {
        NSLog(@"Need to create Objective-C segment contents.");
        // Nah, just extract the Objc info later
    }
#endif

    return self;
}

// TODO (2003-12-06)(done): It might be better to just set 'sections' directly and not return the array.
- (void)_processSections;
{
    NSMutableArray *sects;
    const struct section *ptr;
    int count, index;

    // PRECONDITION: sections == nil
    // POSTCONDITION: sections != nil

    sects = [[NSMutableArray alloc] init];

    ptr = (const struct section *)(segmentCommand + 1);
    count = segmentCommand->nsects;
    for (index = 0; index < count; index++) {
        CDSection *section;

        section = [[CDSection alloc] initWithPointer:ptr segment:self];
        [sects addObject:section];
        [section release];

        ptr++;
    }

    sections = [[NSArray alloc] initWithArray:sects];
    [sects release];
}

- (void)dealloc;
{
    [name release];
    [sections release];

    [super dealloc];
}

- (NSString *)name;
{
    return name;
}

- (unsigned long)vmaddr;
{
    return segmentCommand->vmaddr;
}

- (unsigned long)fileoff;
{
    return segmentCommand->fileoff;
}

- (unsigned long)flags;
{
    return segmentCommand->flags;
}

- (NSArray *)sections;
{
    return sections;
}

- (NSString *)flagDescription;
{
    NSMutableArray *setFlags;
    unsigned long flags;

    setFlags = [NSMutableArray array];
    flags = [self flags];
    if (flags & SG_HIGHVM)
        [setFlags addObject:@"HIGHVM"];
    if (flags & SG_FVMLIB)
        [setFlags addObject:@"FVMLIB"];
    if (flags & SG_NORELOC)
        [setFlags addObject:@"NORELOC"];

    return [setFlags componentsJoinedByString:@" "];
}

- (NSString *)extraDescription;
{
    return [NSString stringWithFormat:@"name: '%@', vmaddr: 0x%08x - 0x%08x [0x%08x], offset: %d, flags: 0x%x (%@), nsects: %d, sections: %@",
                     name, segmentCommand->vmaddr, segmentCommand->vmaddr + segmentCommand->vmsize - 1, segmentCommand->vmsize, segmentCommand->fileoff,
                     [self flags], [self flagDescription], segmentCommand->nsects, sections];
}

// TODO (2003-12-06): Might want to make this a range.
- (BOOL)containsAddress:(unsigned long)vmaddr;
{
    return (vmaddr >= segmentCommand->vmaddr) && (vmaddr < segmentCommand->vmaddr + segmentCommand->vmsize);
}

- (CDSection *)sectionContainingVMAddr:(unsigned long)vmaddr;
{
    int count, index;

    count = [sections count];
    for (index = 0; index < count; index++) {
        CDSection *aSection;

        aSection = [sections objectAtIndex:index];
        if ([aSection containsAddress:vmaddr] == YES)
            return aSection;
    }

    return nil;
}

- (unsigned long)segmentOffsetForVMAddr:(unsigned long)vmaddr;
{
    CDSection *section;

    section = [self sectionContainingVMAddr:vmaddr];
    NSLog(@"section: %@", section);

    return [section segmentOffsetForVMAddr:vmaddr];
}

- (CDSection *)sectionWithName:(NSString *)aName;
{
    int count, index;

    count = [sections count];
    for (index = 0; index < count; index++) {
        CDSection *aSection;

        aSection = [sections objectAtIndex:index];
        if ([[aSection sectionName] isEqual:aName] == YES)
            return aSection;
    }

    return nil;
}

@end
