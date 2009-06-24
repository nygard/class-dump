//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import "CDObjectiveCProcessor.h"

#import "CDClassDump.h"
#import "CDMachOFile.h"
#import "CDVisitor.h"

@implementation CDObjectiveCProcessor

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

- (BOOL)hasObjectiveCData;
{
    // Implement in subclasses.
    return NO;
}

- (void)process;
{
    // Implement in subclasses.
}

- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;
{
    // Implement in subclasses.
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> machOFile: %@",
                     NSStringFromClass([self class]), self,
                     [machOFile filename]];
}

- (void)recursivelyVisit:(CDVisitor *)aVisitor;
{
    // Implement in subclasses.
}

@end
