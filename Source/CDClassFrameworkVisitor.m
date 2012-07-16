// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDClassFrameworkVisitor.h"

#import "CDMachOFile.h"
#import "CDOCClass.h"
#import "CDObjectiveCProcessor.h"

@interface CDClassFrameworkVisitor ()
@property (strong) NSString *frameworkName;
@end

#pragma mark -

@implementation CDClassFrameworkVisitor
{
    NSMutableDictionary *_frameworkNamesByClassName;
    NSString *_frameworkName;
}

- (id)init;
{
    if ((self = [super init])) {
        _frameworkNamesByClassName = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

#pragma mark -

- (void)willVisitObjectiveCProcessor:(CDObjectiveCProcessor *)processor;
{
    self.frameworkName = processor.machOFile.importBaseName;
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    [self addClassName:aClass.name referencedInFramework:self.frameworkName];
}

#pragma mark -

- (void)addClassName:(NSString *)name referencedInFramework:(NSString *)frameworkName;
{
    if (name != nil && frameworkName != nil)
        _frameworkNamesByClassName[name] = frameworkName;
}

- (NSDictionary *)frameworkNamesByClassName;
{
    return [_frameworkNamesByClassName copy];
}

@end
