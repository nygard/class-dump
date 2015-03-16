#import "CDXibStoryboardParser.h"
#import "GDataXMLNode.h"


@implementation CDXibStoryboardParser {

}

- (NSArray *)symbolsInFile:(NSURL *)fileUrl {
    NSMutableArray *array = [NSMutableArray array];

    NSData *data = [NSData dataWithContentsOfURL:fileUrl];
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:data error:nil];

    [self addSymbolsFromNode:doc.rootElement toArray:array];

    return array;
}

- (void)addSymbolsFromNode:(GDataXMLElement *)xmlDictionary toArray:(NSMutableArray *)symbolsArray {
    NSArray *childNodes = xmlDictionary.children;

    // Check if element contains a custom class element and add it to obfuscated classes list
    GDataXMLNode *attribute = [xmlDictionary attributeForName:@"customClass"];
    if (attribute) {
        [symbolsArray addObject:attribute.stringValue];
    }

    // Check if element contains an outlet to obfuscate
    if ([xmlDictionary.name isEqualToString:@"outlet"]) {
        GDataXMLNode *propertyName = [xmlDictionary attributeForName:@"property"];
        if (propertyName) {
            [symbolsArray addObject:propertyName.stringValue];
        }
    }

    for (GDataXMLElement *childNode in childNodes) {
        // Skip comments
        if ([childNode isKindOfClass:[GDataXMLElement class]]) {
            [self addSymbolsFromNode:childNode toArray:symbolsArray];
        }
    }
}


- (void)obfuscateFilesUsingSymbols:(NSDictionary *)symbols {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *keys = @[NSURLIsDirectoryKey];
    NSURL *directoryURL = [NSURL URLWithString:@"."];

    NSDirectoryEnumerator *enumerator = [fileManager
        enumeratorAtURL:directoryURL
        includingPropertiesForKeys:keys
        options:0
        errorHandler:^(NSURL *url, NSError *error) {
            // Handle the error.
            // Return YES if the enumeration should continue after the error.
            return YES;
    }];

    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error] && ![isDirectory boolValue]) {
            if ([url.absoluteString hasSuffix:@".xib"] || [url.absoluteString hasSuffix:@".storyboard"]) {
                [self obfuscatedXmlData:url symbols:symbols];
            }
        }
    }
}

- (NSData *)obfuscatedXmlData:(NSData *)data symbols:(NSDictionary *)symbols {
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:data error:nil];

    [self obfuscateElement:doc.rootElement usingSymbols:symbols];

    return doc.XMLData;
}

- (void)obfuscateElement:(GDataXMLElement *)element usingSymbols:(NSDictionary *)symbols {
    NSArray *childNodes = element.children;

    // Check if element contains a custom class element and add it to obfuscated classes list
    GDataXMLNode *attribute = [element attributeForName:@"customClass"];
    if (attribute && symbols[attribute.stringValue]) {
        [attribute setStringValue:symbols[attribute.stringValue]];
    }

    // Check if element contains an outlet to obfuscate
    if ([element.name isEqualToString:@"outlet"]) {
        GDataXMLNode *propertyName = [element attributeForName:@"property"];
        if (propertyName && symbols[propertyName.stringValue]) {
            [propertyName setStringValue:symbols[propertyName.stringValue]];
        }
    }

    // Check if element contains an action to obfuscate
    if ([element.name isEqualToString:@"action"]) {
        GDataXMLNode *selectorNameNode = [element attributeForName:@"selector"];
        NSMutableString *obfuscatedSelectorName = [selectorNameNode.stringValue mutableCopy];
        NSArray *components = [selectorNameNode.stringValue componentsSeparatedByString:@":"];
        for (NSString *component in components) {
            if (component.length > 0 && symbols[component]) {
                [obfuscatedSelectorName replaceOccurrencesOfString:component withString:symbols[component] options:0 range:NSMakeRange(0, obfuscatedSelectorName.length)];
            }
        }
        [selectorNameNode setStringValue:obfuscatedSelectorName];
    }

    // Check if element contains outlet collection
    if ([element.name isEqualToString:@"outletCollection"]) {
        GDataXMLNode *propertyName = [element attributeForName:@"property"];
        if (propertyName && symbols[propertyName.stringValue]) {
            [propertyName setStringValue:symbols[propertyName.stringValue]];
        }
    }

    // Recursively process rest of the elements
    for (GDataXMLElement *childNode in childNodes) {
        // Skip comments
        if ([childNode isKindOfClass:[GDataXMLElement class]]) {
            [self obfuscateElement:childNode usingSymbols:symbols];
        }
    }
}

@end
