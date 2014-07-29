#import "CDXMLParserSharedBase.h"
#import "GDataXMLNode.h"


@implementation CDXMLParserSharedBase

- (NSArray *)symbolsInData:(NSData *)data {
    NSMutableArray *array = [NSMutableArray array];

    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:data error:nil];

    [self addSymbolsFromNode:doc.rootElement toArray:array];

    return array;
}

- (NSData *)obfuscatedXmlData:(NSData *)data symbols:(NSDictionary *)symbols {
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:data error:nil];

    [self obfuscateElement:doc.rootElement usingSymbols:symbols];

    return doc.XMLData;
}

- (void)addSymbolsFromNode:(GDataXMLElement *)xmlDictionary toArray:(NSMutableArray *)symbolsArray {}
- (void)obfuscateElement:(GDataXMLElement *)element usingSymbols:(NSDictionary *)symbols {}

@end
