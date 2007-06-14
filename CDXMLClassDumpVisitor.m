//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "CDXMLClassDumpVisitor.h"

#import "CDClassDump.h"
#import "CDObjCSegmentProcessor.h"

@implementation CDXMLClassDumpVisitor

- (id)init;
{
    if ([super init] == nil)
        return nil;

    xmlDocument = nil;

    return self;
}

- (void)dealloc;
{
    [xmlDocument release];

    [super dealloc];
}

- (void)_setXMLDocument:(NSXMLDocument *)newXMLDocument;
{
    if (newXMLDocument == xmlDocument)
        return;

    [xmlDocument release];
    xmlDocument = [newXMLDocument retain];
}

- (void)willBeginVisiting;
{
    NSString *emptyXMLDocumentString;
    NSString *rootElementName = @"class-dump";
    NSXMLDocument *emptyXMLDocument;
    NSError *error;

    // TODO (2007-06-14): Move the public/system IDs into this class
    emptyXMLDocumentString = [NSString stringWithFormat:@"<?xml version='1.0' encoding='UTF-8'?>\n<!DOCTYPE %@ PUBLIC \"%@\" \"%@\">\n<%@>\n</%@>\n",
                                       rootElementName, [[classDump class] currentPublicID], [[classDump class] currentSystemID],
                                       rootElementName, rootElementName];

    emptyXMLDocument = [[NSXMLDocument alloc] initWithXMLString:emptyXMLDocumentString options:NSXMLNodeOptionsNone error:&error];
    if (emptyXMLDocument == nil)
        [NSException raise:NSGenericException format:@"Could not create empty xml document: %@", error];

    [self _setXMLDocument:emptyXMLDocument];
}

- (void)didEndVisiting;
{
    [self writeResultToStandardOutput];
}

- (void)writeResultToStandardOutput;
{
    NSData *data;

    data = [xmlDocument XMLDataWithOptions:NSXMLNodePrettyPrint];
    [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];
}

- (void)visitObjectiveCSegment:(CDObjCSegmentProcessor *)anObjCSegment;
{
}

@end
