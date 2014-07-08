#import "CDVisitor.h"


@interface CDSymoblsGeneratorVisitor : CDVisitor
@property (nonatomic, copy) NSArray *classFilter;
@property (nonatomic, copy) NSArray *ignoreSymbols;
@property (nonatomic, readonly) NSString *resultString;
@end
