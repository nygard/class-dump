#import <Foundation/Foundation.h>

@class GDataXMLElement;

@interface CDParserSharedBase : NSObject
- (NSArray *)symbolsInData:(NSData *)data;

- (NSData *)obfuscatedXmlData:(NSData *)data symbols:(NSDictionary *)symbols;

- (void)addSymbolsFromNode:(GDataXMLElement *)xmlDictionary toArray:(NSMutableArray *)symbolsArray;
- (void)obfuscateElement:(GDataXMLElement *)element usingSymbols:(NSDictionary *)symbols;
@end
