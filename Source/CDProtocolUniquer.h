// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

@class CDOCProtocol;

@interface CDProtocolUniquer : NSObject

// Gather
- (CDOCProtocol *)protocolWithAddress:(uint64_t)address;
- (void)setProtocol:(CDOCProtocol *)protocol withAddress:(uint64_t)address;

// Process
- (void)createUniquedProtocols;

// Results
- (NSArray *)uniqueProtocolsAtAddresses:(NSArray *)addresses;
- (NSArray *)uniqueProtocolsSortedByName;

@end
