#import <Foundation/Foundation.h>


@interface CDXibStoryboardParser : NSObject

- (NSData *)obfuscatedXmlData:(NSData *)data symbols:(NSDictionary *)symbols;
@end
