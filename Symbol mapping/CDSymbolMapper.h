#import <Foundation/Foundation.h>

@class CDSymbolsGeneratorVisitor;


@interface CDSymbolMapper : NSObject

- (void)writeSymbolsFromSymbolsVisitor:(CDSymbolsGeneratorVisitor *)visitor toFile:(NSString *)file;

- (NSString *)processCrashDump:(NSString *)crashDump withSymbols:(NSDictionary *)symbols;
@end
