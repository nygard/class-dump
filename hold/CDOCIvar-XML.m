//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDOCIvar-XML.h"

#import <Cocoa/Cocoa.h>
#import <STFoundation/STFoundation.h>
#import <STAppKit/STAppKit.h>

@implementation CDOCIvar (XML)

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
        if ([aClassDump shouldShowIvarOffsets])
            [ivarElement addChild:[NSXMLElement elementWithName:@"offset" stringValue:[NSString stringWithFormat:@"0x%x", offset]]];
    } else
        [ivarElement addChild:[NSXMLNode commentWithStringValue:[NSString stringWithFormat:@"error parsing type: %@, name: %@", type, name]]];
    //[resultString appendFormat:@"    // Error parsing type: %@, name: %@", type, name];
    [xmlElement addChild:ivarElement];
}

@end
