// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2013 Steve Nygard.

#import "CDClassFrameworkVisitor.h"

#import "CDMachOFile.h"
#import "CDOCClass.h"
#import "CDObjectiveCProcessor.h"
#import "CDSymbol.h"
#import "CDLCDylib.h"

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
    
    // We only need to add superclasses for external classes - classes defined in this binary will be visited on their own
    id superClass = [aClass superClass];
    if ([superClass isKindOfClass:[CDSymbol class]]) {
        CDSymbol *symbol = superClass;
        NSString *frameworkName = CDImportNameForPath([[symbol dylibLoadCommand] path]);
        NSString *className = [CDSymbol classNameFromSymbolName:[symbol name]];
        [self addClassName:className referencedInFramework:frameworkName];
    }
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
