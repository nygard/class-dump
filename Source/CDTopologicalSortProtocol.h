// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

// A rather clunky way to avoid warnings in CDTopoSortNode.m regarding -retain not implemented by protocols
@protocol CDTopologicalSort <NSObject>
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSArray *dependancies;
@end
