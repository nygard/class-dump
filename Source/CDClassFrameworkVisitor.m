// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDClassFrameworkVisitor.h"

#import "CDMachOFile.h"
#import "CDOCClass.h"
#import "CDObjectiveCProcessor.h"

@interface CDClassFrameworkVisitor ()
@property (retain) NSString *frameworkName;
@end

#pragma mark -

@implementation CDClassFrameworkVisitor
{
    NSMutableDictionary *frameworkNamesByClassName;
    NSMutableDictionary *frameworkNamesByProtocolName;
    NSString *frameworkName;
}

- (id)init;
{
    if ((self = [super init])) {
        frameworkNamesByClassName = [[NSMutableDictionary alloc] init];
        frameworkNamesByProtocolName = [[NSMutableDictionary alloc] init];
        frameworkName = nil;
    }

    return self;
}

- (void)dealloc;
{
    [frameworkNamesByClassName release];
    [frameworkNamesByProtocolName release];
    [frameworkName release];

    [super dealloc];
}

#pragma mark -

- (void)willVisitObjectiveCProcessor:(CDObjectiveCProcessor *)processor;
{
    self.frameworkName = processor.machOFile.importBaseName;
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    if (self.frameworkName != nil) {
        [frameworkNamesByClassName setObject:self.frameworkName forKey:aClass.name];
    }
}

- (void)willVisitProtocol:(CDOCProtocol *)protocol;
{
    if (self.frameworkName != nil) {
        [frameworkNamesByProtocolName setObject:self.frameworkName forKey:protocol.name];
    }
}

#pragma mark -

@synthesize frameworkNamesByClassName;
@synthesize frameworkNamesByProtocolName;
@synthesize frameworkName;

@end
