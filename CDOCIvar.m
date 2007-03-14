//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDOCIvar.h"

#import <Foundation/Foundation.h>
#import "CDClassDump.h"
#import "CDTypeFormatter.h"

@implementation CDOCIvar

- (id)initWithName:(NSString *)aName type:(NSString *)aType offset:(int)anOffset;
{
    if ([super init] == nil)
        return nil;

    name = [aName retain];
    type = [aType retain];
    offset = anOffset;

    return self;
}

- (void)dealloc;
{
    [name release];
    [type release];

    [super dealloc];
}

- (NSString *)name;
{
    return name;
}

- (NSString *)type;
{
    return type;
}

- (int)offset;
{
    return offset;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, type: '%@', offset: %d",
                     NSStringFromClass([self class]), name, type, offset];
}

- (void)addToXMLElement:(NSXMLElement *)xmlElement classDump:(CDClassDump *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    NSXMLElement *ivarElement = [NSXMLElement elementWithName:@"ivar"];
    NSDictionary *formattedTypeDict;

    [ivarElement addChild:[NSXMLElement elementWithName:@"name" stringValue:name]];

//    formattedString = [[aClassDump ivarTypeFormatter] formatVariable:nil type:type symbolReferences:symbolReferences];
    formattedTypeDict = [[aClassDump ivarTypeFormatter] formattedTypeComponentsForType:type symbolReferences:symbolReferences];

    if (formattedTypeDict != nil) {
        [ivarElement addChild:[NSXMLElement elementWithName:@"type" stringValue:[formattedTypeDict objectForKey:@"type"]]];
        NSString *typeSuffix = [formattedTypeDict objectForKey:@"type-suffix"];
        if (typeSuffix != nil)
            [ivarElement addChild:[NSXMLElement elementWithName:@"type-suffix" stringValue:typeSuffix]];
        if ([aClassDump shouldShowIvarOffsets] == YES)
            [ivarElement addChild:[NSXMLElement elementWithName:@"offset" stringValue:[NSString stringWithFormat:@"0x%x", offset]]];
    } else
        [ivarElement addChild:[NSXMLNode commentWithStringValue:[NSString stringWithFormat:@"error parsing type: %@, name: %@", type, name]]];
    //[resultString appendFormat:@"    // Error parsing type: %@, name: %@", type, name];
    [xmlElement addChild:ivarElement];
}

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    NSString *formattedString;

    formattedString = [[aClassDump ivarTypeFormatter] formatVariable:name type:type symbolReferences:symbolReferences];
    if (formattedString != nil) {
        [resultString appendString:formattedString];
        [resultString appendString:@";"];
        if ([aClassDump shouldShowIvarOffsets] == YES) {
            [resultString appendFormat:@"\t// %d = 0x%x", offset, offset];
        }
    } else
        [resultString appendFormat:@"    // Error parsing type: %@, name: %@", type, name];
}

@end
