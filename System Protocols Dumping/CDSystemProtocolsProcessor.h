#import <Foundation/Foundation.h>


@interface CDSystemProtocolsProcessor : NSObject
- (id)initWithSdkPath:(NSString *)sdkPath;
- (NSArray *)systemProtocolsSymbolsToExclude;
@end
