//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2006  Steve Nygard

#import "CDOCMethod.h"

#import <Foundation/Foundation.h>
#import "CDClassDump.h"
#import "CDTypeFormatter.h"

@implementation CDOCMethod

- (id)init;
{
    [NSException raise:@"RejectUnusedImplementation" format:@"-initWithName:type:imp: is the designated initializer"];
    return nil;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType imp:(unsigned long)anImp;
{
    if ([super init] == nil)
        return nil;

    name = [aName retain];
    type = [aType retain];
    imp = anImp;

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

- (unsigned long)imp;
{
    return imp;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, type: %@, imp: 0x%08x",

                     NSStringFromClass([self class]), name, type, imp];
}

- (void)addToXMLElement:(NSXMLElement *)xmlElement asClassMethod:(BOOL)asClassMethod classDump:(CDClassDump *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;
{
	NSXMLElement *methodElement = [NSXMLElement elementWithName:(asClassMethod ? @"classmethod" : @"instancemethod")];
	NSDictionary *formattedTypes;
	
	[methodElement addChild:[NSXMLElement elementWithName:@"selector" stringValue:name]];
	formattedTypes = [[aClassDump methodTypeFormatter] formattedTypesForMethodName:name type:type symbolReferences:symbolReferences];
    if (formattedTypes != nil) {
        
		[methodElement addChild:[NSXMLElement elementWithName:@"returntype" stringValue:[formattedTypes valueForKey:@"returntype"]]];
		NSArray *parameterTypes = [formattedTypes valueForKey:@"parametertypes"];
		int count, index;
		count = [parameterTypes count];
		if (count > 0) {
			NSXMLElement *parametersElement = [NSXMLElement elementWithName:@"parameters"];
			for (index = 0; index < count; index++) {
				[parametersElement addChild:[NSXMLElement elementWithName:@"parameter" 
														  children:[NSArray arrayWithObjects:
															  [NSXMLElement elementWithName:@"name" stringValue:[[parameterTypes objectAtIndex:index] valueForKey:@"name"]],
															  [NSXMLElement elementWithName:@"type" stringValue:[[parameterTypes objectAtIndex:index] valueForKey:@"type"]],
															  nil]
														attributes:nil]];
			}
			[methodElement addChild:parametersElement];
		}
		
        if ([aClassDump shouldShowMethodAddresses] == YES && imp != 0)
            [methodElement addChild:[NSXMLElement elementWithName:@"imp" stringValue:[NSString stringWithFormat:@"0x%08x", imp]]];
    } else
        [methodElement addChild:[NSXMLNode commentWithStringValue:[NSString stringWithFormat:@"Error parsing type: %@, name: %@", type, name]]];
	
	[xmlElement addChild:methodElement];
}

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    NSString *formattedString;

    formattedString = [[aClassDump methodTypeFormatter] formatMethodName:name type:type symbolReferences:symbolReferences];
    if (formattedString != nil) {
        [resultString appendString:formattedString];
        [resultString appendString:@";"];
        if ([aClassDump shouldShowMethodAddresses] == YES && imp != 0)
            [resultString appendFormat:@"\t// IMP=0x%08x", imp];
    } else
        [resultString appendFormat:@"    // Error parsing type: %@, name: %@", type, name];
}

- (NSComparisonResult)ascendingCompareByName:(CDOCMethod *)otherMethod;
{
    return [name compare:[otherMethod name]];
}

@end
