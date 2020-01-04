// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@interface CDTypeName : NSObject <NSCopying>

@property (strong) NSString *name;
@property (readonly) NSMutableArray *templateTypes;
@property (strong) NSString *suffix;
@property (nonatomic, readonly) BOOL isTemplateType;

@end
