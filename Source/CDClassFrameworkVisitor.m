// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDClassFrameworkVisitor.h"

#import "CDMachOFile.h"
#import "CDOCClass.h"
#import "CDObjectiveCProcessor.h"
#import "CDSymbol.h"
#import "CDLCDylib.h"
#import "CDOCCategory.h"
#import "CDOCClassReference.h"

@interface CDClassFrameworkVisitor ()
@property (strong) NSString *frameworkName;
@end

#pragma mark -

@implementation CDClassFrameworkVisitor
{
    NSMutableDictionary *_frameworkNamesByClassName;
    NSMutableDictionary *_frameworkNamesByProtocolName;
    NSString *_frameworkName;
}

- (id)init;
{
    if ((self = [super init])) {
        _frameworkNamesByClassName = [[NSMutableDictionary alloc] init];
        _frameworkNamesByProtocolName = [[NSMutableDictionary alloc] init];
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
    CDOCClassReference *superClassRef = [aClass superClassRef];
    if ([superClassRef isExternalClass] && superClassRef.classSymbol != nil) {
        [self addClassForExternalSymbol:superClassRef.classSymbol];
    }
}

- (void)willVisitProtocol:(CDOCProtocol *)protocol;
{
    // TODO: (2012-02-28) Figure out what frameworks use each protocol, and try to pick the correct one.  More difficult because, for example, NSCopying is found in many frameworks, and picking the last one isn't good enough.  Perhaps a topological sort of the dependancies would be better.
    [self addProtocolName:protocol.name referencedInFramework:self.frameworkName];
}

- (void)willVisitCategory:(CDOCCategory *)category;
{
    CDOCClassReference *classRef = [category classRef];
    if ([classRef isExternalClass] && classRef.classSymbol != nil) {
        [self addClassForExternalSymbol:classRef.classSymbol];
    }
}

#pragma mark -

- (void)addClassForExternalSymbol:(CDSymbol *)symbol;
{
    NSString *frameworkName = CDImportNameForPath([[symbol dylibLoadCommand] path]);
    NSString *className = [CDSymbol classNameFromSymbolName:[symbol name]];
    [self addClassName:className referencedInFramework:frameworkName];
}

- (void)addClassName:(NSString *)name referencedInFramework:(NSString *)frameworkName;
{
    if (name != nil && frameworkName != nil)
        _frameworkNamesByClassName[name] = frameworkName;
}

- (void)addProtocolName:(NSString *)name referencedInFramework:(NSString *)frameworkName;
{
    if (name != nil && frameworkName != nil)
        _frameworkNamesByProtocolName[name] = frameworkName;
}

- (NSDictionary *)frameworkNamesByClassName;
{
    return [_frameworkNamesByClassName copy];
}

- (NSDictionary *)frameworkNamesByProtocolName;
{
    return [_frameworkNamesByProtocolName copy];
}

@end
