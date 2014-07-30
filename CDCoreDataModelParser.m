#import "CDCoreDataModelParser.h"
#import "GDataXMLNode.h"


@implementation CDCoreDataModelParser

- (void)addSymbolsFromNode:(GDataXMLElement *)element toArray:(NSMutableArray *)symbolsArray {
    NSArray *childNodes = element.children;

    // Get the class name
    GDataXMLNode *className = [element attributeForName:@"representedClassName"];
    if (className) {
        [symbolsArray addObject:[NSString stringWithFormat:@"!%@", className.stringValue]];
    }

    // Get the class name
    GDataXMLNode *parentClassName = [element attributeForName:@"parentEntity"];
    if (parentClassName) {
        [symbolsArray addObject:[NSString stringWithFormat:@"!%@", parentClassName.stringValue]];
    }

    // Recursively process rest of the elements
    for (GDataXMLElement *childNode in childNodes) {
        // Skip comments
        if ([childNode isKindOfClass:[GDataXMLElement class]]) {
            [self addSymbolsFromNode:childNode toArray:symbolsArray];
        }
    }
}

- (void)obfuscateElement:(GDataXMLElement *)element usingSymbols:(NSDictionary *)symbols {
    // TODO implement later
}


@end
