// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCLinkeditData.h"

#import "CDMachOFile.h"

@implementation CDLCLinkeditData
{
    struct linkedit_data_command linkeditDataCommand;
    NSData *linkeditData;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        linkeditDataCommand.cmd = [cursor readInt32];
        linkeditDataCommand.cmdsize = [cursor readInt32];
        
        linkeditDataCommand.dataoff = [cursor readInt32];
        linkeditDataCommand.datasize = [cursor readInt32];
    }

    return self;
}

- (void)dealloc;
{
    [linkeditData release];
    
    [super dealloc];
}

#pragma mark -

- (uint32_t)cmd;
{
    return linkeditDataCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return linkeditDataCommand.cmdsize;
}

- (NSData *)linkeditData;
{
    if (linkeditData == NULL) {
        linkeditData = [[NSData alloc] initWithBytes:[self.machOFile bytesAtOffset:linkeditDataCommand.dataoff] length:linkeditDataCommand.datasize];
    }
    
    return linkeditData;
}

@end
