// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "CDTextClassDumpVisitor.h"

#import "CDTypeController.h" // For CDTypeControllerDelegate protocol

// This generates separate files for each class.  Files are created in the 'outputPath' directory.

@interface CDMultiFileVisitor : CDTextClassDumpVisitor <CDTypeControllerDelegate>

@property (strong) NSString *outputPath;

@end
