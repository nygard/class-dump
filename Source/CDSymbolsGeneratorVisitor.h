#import "CDVisitor.h"


@interface CDSymbolsGeneratorVisitor : CDVisitor
@property (nonatomic, copy) NSArray *classFilter;
@property (nonatomic, copy) NSArray *ignoreSymbols;
@property (nonatomic, readonly) NSString *resultString;
@property (nonatomic, readonly) NSDictionary *symbols;
@property(nonatomic, copy) NSString *symbolsFilePath;
- (void)addSymbolsPadding;
@end
