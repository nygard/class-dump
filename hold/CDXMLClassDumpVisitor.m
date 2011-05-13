//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDXMLClassDumpVisitor.h"

#include <mach-o/arch.h>

#import "NSArray-Extensions.h"
#import "CDClassDump.h"
#import "CDObjCSegmentProcessor.h"
#import "CDMachOFile.h"
#import "CDOCProtocol.h"
#import "CDDylibCommand.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDSymbolReferences.h"
#import "CDOCMethod.h"
#import "CDOCIvar.h"

// TODO: Dump structures, equivalent of CDStructures.h

@implementation CDXMLClassDumpVisitor

- (id)init;
{
    if ([super init] == nil)
        return nil;

    xmlDocument = nil;
    elementStack = [[NSMutableArray alloc] init];
    symbolReferences = nil;

    return self;
}

- (void)dealloc;
{
    [xmlDocument release];
    [elementStack release];
    [symbolReferences release];

    [super dealloc];
}

- (void)_setXMLDocument:(NSXMLDocument *)newXMLDocument;
{
    if (newXMLDocument == xmlDocument)
        return;

    [xmlDocument release];
    xmlDocument = [newXMLDocument retain];
}

- (void)pushElement:(NSXMLElement *)anElement;
{
    [elementStack addObject:anElement];
}

- (void)popElement;
{
    [elementStack removeLastObject];
}

- (NSXMLElement *)currentElement;
{
    return [elementStack lastObject];
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
    [self pushElement:[xmlDocument rootElement]];

    if ([classDump containsObjectiveCSegments]) {
        //[classDump appendStructuresToString:resultString symbolReferences:nil];
    } else {
        [[self currentElement] addChild:[NSXMLNode commentWithStringValue:@"This file does not contain any Objective-C runtime information."]];
    }
}

- (void)didEndVisiting;
{
    [self popElement];
    [self writeResultToStandardOutput];
}

- (void)writeResultToStandardOutput;
{
    NSData *data;

    data = [xmlDocument XMLDataWithOptions:NSXMLNodePrettyPrint];
    [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];

    data = [@"\n" dataUsingEncoding:NSUTF8StringEncoding];
    [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];
}

- (void)willVisitObjectiveCSegment:(CDObjCSegmentProcessor *)anObjCSegment;
{
    NSXMLElement *fileElement;

    fileElement = [NSXMLElement elementWithName:@"file"];
    [[self currentElement] addChild:fileElement];
    [self pushElement:fileElement];
}

- (void)visitObjectiveCSegment:(CDObjCSegmentProcessor *)anObjCSegment;
{
    CDMachOFile *machOFile;
    const NXArchInfo *archInfo;
    NSXMLElement *fileElement, *nameElement;

    machOFile = [anObjCSegment machOFile];

    fileElement = [self currentElement];
    nameElement = [NSXMLElement elementWithName:@"name"];
    [nameElement setStringValue:[machOFile filename]];

    [fileElement addChild:nameElement];

    archInfo = NXGetArchInfoFromCpuType([machOFile cpuType], [machOFile cpuSubtype]);
    if (archInfo != NULL) {
        [fileElement addAttribute:[NSXMLNode attributeWithName:@"arch" stringValue:[NSString stringWithFormat:@"%s", archInfo->name]]];
    }

    if ([machOFile filetype] == MH_DYLIB) {
        CDDylibCommand *identifier;

        identifier = [machOFile dylibIdentifier];
        if (identifier != nil) {
            [fileElement addAttribute:[NSXMLNode attributeWithName:@"current-version" stringValue:[identifier formattedCurrentVersion]]];
            [fileElement addAttribute:[NSXMLNode attributeWithName:@"compatibility-version" stringValue:[identifier formattedCompatibilityVersion]]];
        }
    }
}

- (void)didVisitObjectiveCSegment:(CDObjCSegmentProcessor *)anObjCSegment;
{
    [self popElement];
}

- (void)willVisitProtocol:(CDOCProtocol *)aProtocol;
{
    NSXMLElement *protocolElement;

    protocolElement = [NSXMLElement elementWithName:@"protocol"];

    [protocolElement addChild:[NSXMLElement elementWithName:@"name" stringValue:[aProtocol name]]];
    if ([[aProtocol protocols] count] > 0) {
        NSArray *protocolNames;
        int count, index;
        NSMutableArray *adoptedProtocolElements;

        protocolNames = [[aProtocol protocols] arrayByMappingSelector:@selector(name)];
        count = [protocolNames count];

        adoptedProtocolElements = [NSMutableArray array];

        for (index = 0; index < count; index++) {
            [adoptedProtocolElements addObject:[NSXMLElement elementWithName:@"name" stringValue:[protocolNames objectAtIndex:index]]];
        }

        [protocolElement addChild:[NSXMLElement elementWithName:@"adopted-protocols" children:adoptedProtocolElements attributes:nil]];
        [symbolReferences addProtocolNamesFromArray:protocolNames];
    }

    [[self currentElement] addChild:protocolElement];
    [self pushElement:protocolElement];
}

- (void)didVisitProtocol:(CDOCProtocol *)aProtocol;
{
    [self popElement];
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    NSXMLElement *classElement;

    classElement = [NSXMLElement elementWithName:@"class"];
    [classElement addChild:[NSXMLElement elementWithName:@"name" stringValue:[aClass name]]];

    if ([aClass superClassName] != nil)
        [classElement addChild:[NSXMLElement elementWithName:@"superclass" stringValue:[aClass superClassName]]];

    if ([[aClass protocols] count] > 0) {
        NSArray *protocolNames;
        int count, index;
        NSMutableArray *adoptedProtocolElements;

        protocolNames = [[aClass protocols] arrayByMappingSelector:@selector(name)];
        count = [protocolNames count];

        adoptedProtocolElements = [NSMutableArray array];

        for (index = 0; index < count; index++) {
            [adoptedProtocolElements addObject:[NSXMLElement elementWithName:@"name" stringValue:[protocolNames objectAtIndex:index]]];
        }

        [classElement addChild:[NSXMLElement elementWithName:@"adopted-protocols" children:adoptedProtocolElements attributes:nil]];
        [symbolReferences addProtocolNamesFromArray:protocolNames];
    }

    [[self currentElement] addChild:classElement];
    [self pushElement:classElement];
}

- (void)didVisitClass:(CDOCClass *)aClass;
{
    [self popElement];
}

- (void)willVisitIvarsOfClass:(CDOCClass *)aClass;
{
}

- (void)didVisitIvarsOfClass:(CDOCClass *)aClass;
{
}

- (void)willVisitCategory:(CDOCCategory *)aCategory;
{
    NSXMLElement *categoryElement;

    categoryElement = [NSXMLElement elementWithName:@"category"];

    [categoryElement addChild:[NSXMLElement elementWithName:@"name" stringValue:[aCategory name]]];
    [categoryElement addChild:[NSXMLElement elementWithName:@"class-name" stringValue:[aCategory className]]];

    if ([[aCategory protocols] count] > 0) {
        NSArray *protocolNames;
        int count, index;
        NSMutableArray *adoptedProtocolElements;

        protocolNames = [[aCategory protocols] arrayByMappingSelector:@selector(name)];
        count = [protocolNames count];

        adoptedProtocolElements = [NSMutableArray array];

        for (index = 0; index < count; index++) {
            [adoptedProtocolElements addObject:[NSXMLElement elementWithName:@"name" stringValue:[protocolNames objectAtIndex:index]]];
        }

        [categoryElement addChild:[NSXMLElement elementWithName:@"adopted-protocols" children:adoptedProtocolElements attributes:nil]];
        [symbolReferences addProtocolNamesFromArray:protocolNames];
    }

    [[self currentElement] addChild:categoryElement];
    [self pushElement:categoryElement];
}

- (void)didVisitCategory:(CDOCCategory *)aCategory;
{
    [self popElement];
}

- (void)visitClassMethod:(CDOCMethod *)aMethod;
{
    [aMethod addToXMLElement:[self currentElement] asClassMethod:YES classDump:classDump symbolReferences:symbolReferences];
}

- (void)visitInstanceMethod:(CDOCMethod *)aMethod;
{
    [aMethod addToXMLElement:[self currentElement] asClassMethod:NO classDump:classDump symbolReferences:symbolReferences];
}

- (void)visitIvar:(CDOCIvar *)anIvar;
{
    [anIvar addToXMLElement:[self currentElement] classDump:classDump symbolReferences:symbolReferences];
}


@end
