// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDFindMethodVisitor.h"

#import "CDClassDump.h"
#import "CDObjectiveC1Processor.h"
#import "CDMachOFile.h"
#import "CDOCProtocol.h"
#import "CDLCDylib.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDOCMethod.h"
//#import "CDTypeController.h"

@interface CDFindMethodVisitor ()
@property (nonatomic, strong) CDOCProtocol *context;
- (void)showContextIfNecessary;
- (void)writeResultToStandardOutput;
@end

#pragma mark -

@implementation CDFindMethodVisitor
{
    NSString *searchString;
    NSMutableString *resultString;
    CDOCProtocol *context;
    BOOL hasShownContext;
}

- (id)init;
{
    if ((self = [super init])) {
        searchString = nil;
        resultString = [[NSMutableString alloc] init];
        context = nil;
        hasShownContext = NO;
    }

    return self;
}

#pragma mark -

- (void)willBeginVisiting;
{
    [self.classDump appendHeaderToString:resultString];

    if (self.classDump.hasObjectiveCRuntimeInfo) {
        //[[classDump typeController] appendStructuresToString:resultString symbolReferences:nil];
        //[resultString appendString:@"// [structures go here]\n"];
    }
}

- (void)visitObjectiveCProcessor:(CDObjectiveCProcessor *)processor;
{
    if (!self.classDump.hasObjectiveCRuntimeInfo) {
        [resultString appendString:@"//\n"];
        [resultString appendString:@"// This file does not contain any Objective-C runtime information.\n"];
        [resultString appendString:@"//\n"];
    }
}

- (void)didEndVisiting;
{
    [self writeResultToStandardOutput];
}

- (void)writeResultToStandardOutput;
{
    NSData *data = [resultString dataUsingEncoding:NSUTF8StringEncoding];
    [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];
}

- (void)willVisitProtocol:(CDOCProtocol *)protocol;
{
    [self setContext:protocol];
}

- (void)didVisitProtocol:(CDOCProtocol *)protocol;
{
    if (hasShownContext)
        [resultString appendString:@"\n"];
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    [self setContext:aClass];
}

- (void)didVisitClass:(CDOCClass *)aClass;
{
    if (hasShownContext)
        [resultString appendString:@"\n"];
}

- (void)willVisitIvarsOfClass:(CDOCClass *)aClass;
{
}

- (void)didVisitIvarsOfClass:(CDOCClass *)aClass;
{
}

- (void)willVisitCategory:(CDOCCategory *)category;
{
    [self setContext:category];
}

- (void)didVisitCategory:(CDOCCategory *)category;
{
    if (hasShownContext)
        [resultString appendString:@"\n"];
}

- (void)visitClassMethod:(CDOCMethod *)method;
{
    NSRange range = [method.name rangeOfString:searchString];
    if (range.length > 0) {
        [self showContextIfNecessary];

        [resultString appendString:@"+ "];
        [method appendToString:resultString typeController:self.classDump.typeController symbolReferences:nil];
        [resultString appendString:@"\n"];
    }
}

- (void)visitInstanceMethod:(CDOCMethod *)method propertyState:(CDVisitorPropertyState *)propertyState;
{
    NSRange range = [method.name rangeOfString:searchString];
    if (range.length > 0) {
        [self showContextIfNecessary];

        [resultString appendString:@"- "];
        [method appendToString:resultString typeController:self.classDump.typeController symbolReferences:nil];
        [resultString appendString:@"\n"];
    }
}

- (void)visitIvar:(CDOCIvar *)ivar;
{
}

#pragma mark -

@synthesize searchString;
@synthesize context;

- (void)setContext:(CDOCProtocol *)newContext;
{
    if (newContext != context) {
        context = newContext;
        hasShownContext = NO;
    }
}

- (void)showContextIfNecessary;
{
    if (hasShownContext == NO) {
        [resultString appendString:[self.context findTag:nil]];
        [resultString appendString:@"\n"];
        hasShownContext = YES;
    }
}

@end
