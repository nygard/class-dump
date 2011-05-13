//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDOCMethod-XML.h"

#import <Cocoa/Cocoa.h>
#import <STFoundation/STFoundation.h>
#import <STAppKit/STAppKit.h>

@implementation CDOCMethod (XML)

- (void)addToXMLElement:(NSXMLElement *)xmlElement asClassMethod:(BOOL)asClassMethod classDump:(CDClassDump *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    NSXMLElement *methodElement = [NSXMLElement elementWithName:(asClassMethod ? @"class-method" : @"instance-method")];
    NSDictionary *formattedTypes;

    [methodElement addChild:[NSXMLElement elementWithName:@"selector" stringValue:name]];
    formattedTypes = [[aClassDump methodTypeFormatter] formattedTypesForMethodName:name type:type symbolReferences:symbolReferences];
    if (formattedTypes != nil) {
        int count, index;
        NSArray *parameterTypes = [formattedTypes valueForKey:@"parametertypes"];

        [methodElement addChild:[NSXMLElement elementWithName:@"return-type" stringValue:[formattedTypes valueForKey:@"return-type"]]];
        count = [parameterTypes count];
        if (count > 0) {
            for (index = 0; index < count; index++) {
                [methodElement addChild:[NSXMLElement elementWithName:@"parameter"
                                                      children:[NSArray arrayWithObjects:
                                                                            [NSXMLElement elementWithName:@"name" stringValue:[[parameterTypes objectAtIndex:index] valueForKey:@"name"]],
                                                                        [NSXMLElement elementWithName:@"type" stringValue:[[parameterTypes objectAtIndex:index] valueForKey:@"type"]],
                                                                        nil]
                                                      attributes:nil]];
            }
        }

        if ([aClassDump shouldShowMethodAddresses] && imp != 0)
            [methodElement addChild:[NSXMLElement elementWithName:@"address" stringValue:[NSString stringWithFormat:@"0x%08x", imp]]];
    } else
        [methodElement addChild:[NSXMLNode commentWithStringValue:[NSString stringWithFormat:@"Error parsing type: %@, name: %@", type, name]]];

    [xmlElement addChild:methodElement];
}

@end
