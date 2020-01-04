// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@interface CDSearchPathState : NSObject

@property (nonatomic, strong) NSString *executablePath;

- (void)pushSearchPaths:(NSArray *)searchPaths;
- (void)popSearchPaths;

- (NSArray *)searchPaths;

@end
