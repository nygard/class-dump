//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import "CDObjC2.h"

#import "CDMachOFile.h"
#import "CDSection.h"
#import "CDLCSegment.h"

@implementation CDObjC2

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
{
    if ([super init] == nil)
        return nil;

    machOFile = [aMachOFile retain];

    return self;
}

- (void)dealloc;
{
    [machOFile release];

    [super dealloc];
}

- (CDMachOFile *)machOFile;
{
    return machOFile;
}

- (void)process;
{
    CDLCSegment *segment, *s2;
    NSUInteger dataOffset;
    NSString *str;
    CDSection *section;
    NSData *sectionData;
    CDDataCursor *cursor;

    NSLog(@" > %s", _cmd);

    NSLog(@"machOFile: %@", machOFile);
    NSLog(@"load commands: %@", [machOFile loadCommands]);

    segment = [machOFile segmentWithName:@"__DATA"];
    NSLog(@"data segment offset: %lx", [segment fileoff]);
    NSLog(@"data segment: %@", segment);
    [segment writeSectionData];

    section = [segment sectionWithName:@"__objc_classlist"];
    NSLog(@"section: %@", section);

    sectionData = [section data];
    cursor = [[CDDataCursor alloc] initWithData:sectionData];
    while ([cursor isAtEnd] == NO) {
        uint64_t val;

        val = [cursor readLittleInt64];
        NSLog(@"val: %16lx", val);
    }
    [cursor release];

    s2 = [machOFile segmentContainingAddress:0x2cab60];
    NSLog(@"s2 contains 0x2cab60: %@", s2);

    dataOffset = [machOFile dataOffsetForAddress:0x2cab60];
    NSLog(@"dataOffset: %lx (%lu)", dataOffset, dataOffset);

    str = [machOFile stringAtAddress:0x2cac00];
    NSLog(@"str: %@", str);

    NSLog(@"<  %s", _cmd);
}

@end
