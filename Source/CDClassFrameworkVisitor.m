// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDClassFrameworkVisitor.h"

#import "CDMachOFile.h"
#import "CDOCClass.h"
#import "CDObjectiveCProcessor.h"
#import "CDSymbolReferences.h"

@interface CDClassFrameworkVisitor ()
@property  NSString *frameworkName;
@end

#pragma mark -

@implementation CDClassFrameworkVisitor
{
    CDSymbolReferences *_symbolReferences;
    NSString *_frameworkName;
}

#pragma mark -

- (void)willVisitObjectiveCProcessor:(CDObjectiveCProcessor *)processor;
{
    self.frameworkName = processor.machOFile.importBaseName;
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    [self.symbolReferences addClassName:aClass.name referencedInFramework:self.frameworkName];
}

#pragma mark -

@synthesize symbolReferences = _symbolReferences;
@synthesize frameworkName = _frameworkName;

@end
