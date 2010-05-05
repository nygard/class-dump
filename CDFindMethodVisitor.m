// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDFindMethodVisitor.h"

#import "NSArray-Extensions.h"
#import "CDClassDump.h"
#import "CDObjectiveC1Processor.h"
#import "CDMachOFile.h"
#import "CDOCProtocol.h"
#import "CDLCDylib.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDOCMethod.h"
#import "CDTypeController.h"

@implementation CDFindMethodVisitor

- (id)init;
{
    if ([super init] == nil)
        return nil;

    findString = nil;
    resultString = [[NSMutableString alloc] init];
    context = nil;
    hasShownContext = NO;

    return self;
}

- (void)dealloc;
{
    [findString release];
    [resultString release];
    [context release];

    [super dealloc];
}

- (NSString *)findString;
{
    return findString;
}

- (void)setFindString:(NSString *)newFindString;
{
    if (newFindString == findString)
        return;

    [findString release];
    findString = [newFindString retain];
}

- (void)setContext:(CDOCProtocol *)newContext;
{
    if (newContext == context)
        return;

    [context release];
    context = [newContext retain];

    hasShownContext = NO;
}

- (void)showContextIfNecessary;
{
    if (hasShownContext == NO) {
        [resultString appendString:[context findTag:nil]];
        [resultString appendString:@"\n"];
        hasShownContext = YES;
    }
}

- (void)willBeginVisiting;
{
    [classDump appendHeaderToString:resultString];

    if ([classDump containsObjectiveCData] || [classDump hasEncryptedFiles]) {
        //[[classDump typeController] appendStructuresToString:resultString symbolReferences:nil];
        //[resultString appendString:@"// [structures go here]\n"];
    } else {
        [resultString appendString:@"This file does not contain any Objective-C runtime information.\n"];
    }
}

- (void)didEndVisiting;
{
    [self writeResultToStandardOutput];
}

- (void)writeResultToStandardOutput;
{
    NSData *data;

    data = [resultString dataUsingEncoding:NSUTF8StringEncoding];
    [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];
}

- (void)willVisitProtocol:(CDOCProtocol *)aProtocol;
{
    [self setContext:aProtocol];
}

- (void)didVisitProtocol:(CDOCProtocol *)aProtocol;
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

- (void)willVisitCategory:(CDOCCategory *)aCategory;
{
    [self setContext:aCategory];
}

- (void)didVisitCategory:(CDOCCategory *)aCategory;
{
    if (hasShownContext)
        [resultString appendString:@"\n"];
}

- (void)visitClassMethod:(CDOCMethod *)aMethod;
{
    NSRange range;

    range = [[aMethod name] rangeOfString:findString];
    if (range.length > 0) {
        [self showContextIfNecessary];

        [resultString appendString:@"+ "];
        [aMethod appendToString:resultString typeController:[classDump typeController] symbolReferences:nil];
        [resultString appendString:@"\n"];
    }
}

- (void)visitInstanceMethod:(CDOCMethod *)aMethod propertyState:(CDVisitorPropertyState *)propertyState;
{
    NSRange range;

    range = [[aMethod name] rangeOfString:findString];
    if (range.length > 0) {
        [self showContextIfNecessary];

        [resultString appendString:@"- "];
        [aMethod appendToString:resultString typeController:[classDump typeController] symbolReferences:nil];
        [resultString appendString:@"\n"];
    }
}

- (void)visitIvar:(CDOCIvar *)anIvar;
{
}

@end
