#import "CDSymbolMapper.h"
#import "CDSymbolsGeneratorVisitor.h"


@implementation CDSymbolMapper {

}
- (void)writeSymbolsFromSymbolsVisitor:(CDSymbolsGeneratorVisitor *)visitor toFile:(NSString *)file {
    NSMutableDictionary *invertedSymbols = [NSMutableDictionary dictionary];
    for (NSString *key in [visitor.symbols allKeys]) {
        invertedSymbols[visitor.symbols[key]] = key;
    }

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:invertedSymbols options:NSJSONWritingPrettyPrinted error:nil];
    [jsonData writeToFile:file atomically:YES];
}

- (NSString *)processCrashDump:(NSString *)crashDump withSymbols:(NSDictionary *)symbols {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[.*\\]" options:NSRegularExpressionCaseInsensitive error:nil];
    NSMutableString *mutableCrashDump = [crashDump mutableCopy];
    NSArray *matches = [regex matchesInString:crashDump options:NSMatchingReportCompletion range:NSMakeRange(0, mutableCrashDump.length)];
    for (NSTextCheckingResult *result in matches) {
        NSString *match = [crashDump substringWithRange:result.range];
        NSString *symbolicatedCrash = [self realMethodForString:match range:result.range symbols:symbols];
        [mutableCrashDump replaceOccurrencesOfString:match withString:symbolicatedCrash options:0 range:NSMakeRange(0, mutableCrashDump.length)];
    }
    return mutableCrashDump;
}

- (NSString *)realMethodForString:(NSString *)mutableCrashDump range:(NSRange)range symbols:(NSDictionary *)symbols {
    NSString *match = mutableCrashDump;
    match = [match stringByReplacingOccurrencesOfString:@"[" withString:@""];
    match = [match stringByReplacingOccurrencesOfString:@"]" withString:@""];
    NSArray *components = [match componentsSeparatedByString:@" "];
    NSString *className = [components firstObject];

    NSString *methodName = [components lastObject];
    NSArray *methodComponents = [methodName componentsSeparatedByString:@":"];
    NSString *realMethodName = @"";
    for (NSString *component in methodComponents) {
        NSString *symbol = symbols[component];
        if (symbol) {
            realMethodName = [NSString stringWithFormat:@"%@:%@", realMethodName, symbol];
        } else {
            realMethodName = [NSString stringWithFormat:@"%@:%@", realMethodName, component];
        }
    }
    if (realMethodName.length > 0) {
        realMethodName = [realMethodName substringFromIndex:1];
    }

    NSString *realClassName = className;
    NSString *classSymbol = symbols[className];
    if (classSymbol) {
        realClassName = classSymbol;
    }
    return [NSString stringWithFormat:@"[%@ %@]", realClassName, realMethodName];
}


@end
