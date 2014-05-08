#import "CDSymoblsGeneratorVisitor.h"
#import "CDOCProtocol.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDOCMethod.h"
#import "CDVisitorPropertyState.h"
#import "CDOCInstanceVariable.h"
#import "CDOCProperty.h"
#import "CDObjectiveCProcessor.h"
#import "CDMachOFile.h"
#import "CDType.h"

static const int maxLettersSet = 3;
static NSString *const lettersSet[maxLettersSet] = {
        @"abcdefghijklmnopqrstuvwxyz",
        @"0123456789",
        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
};

@implementation CDSymoblsGeneratorVisitor {
    NSMutableSet *_protocolNames;
    NSMutableSet *_classNames;
    NSMutableSet *_categoryNames;
    NSMutableSet *_propertyNames;
    NSMutableSet *_methodNames;
    NSMutableSet *_ivarNames;
    NSMutableSet *_forbiddenNames;

    NSMutableDictionary *_symbols;
    NSMutableSet *_uniqueSymbols;

    NSInteger _symbolLength;
    BOOL _external;
    BOOL _ignored;

    NSMutableString *_resultString;
}

- (void)addForbiddenSymbols {
    [_forbiddenNames addObjectsFromArray:@[@"auto",
            @"break",
            @"case",
            @"char",
            @"const",
            @"continue",
            @"default",
            @"do",
            @"double",
            @"else",
            @"enum",
            @"extern",
            @"float",
            @"for",
            @"goto",
            @"if",
            @"int",
            @"long",
            @"register",
            @"return",
            @"short",
            @"signed",
            @"sizeof",
            @"static",
            @"struct",
            @"switch",
            @"typedef",
            @"union",
            @"unsigned",
            @"void",
            @"volatile",
            @"while",
            @"in",
            @"init",
            @"alloc"
    ]];
}

- (void)willBeginVisiting {
    _protocolNames = [NSMutableSet new];
    _classNames = [NSMutableSet new];
    _categoryNames = [NSMutableSet new];
    _propertyNames = [NSMutableSet new];
    _methodNames = [NSMutableSet new];
    _ivarNames = [NSMutableSet new];
    _symbols = [NSMutableDictionary new];
    _uniqueSymbols = [NSMutableSet new];
    _forbiddenNames = [NSMutableSet new];
    _symbolLength = 3;
    _external = NO;
    _ignored = NO;
    [self addForbiddenSymbols];
}

- (void)didEndVisiting {
    NSLog(@"Generating symbol table...");
    NSLog(@"Protocols = %zd", _protocolNames.count);
    NSLog(@"Classes = %zd", _classNames.count);
    NSLog(@"Categories = %zd", _categoryNames.count);
    NSLog(@"Methods = %zd", _methodNames.count);
    NSLog(@"I-vars = %zd", _ivarNames.count);
    NSLog(@"Forbidden keywords = %zd", _forbiddenNames.count);

    _resultString = [NSMutableString new];

    NSArray *propertyNames = [_propertyNames.allObjects sortedArrayUsingComparator:^NSComparisonResult(NSString *n1, NSString *n2) {
        if (n1.length > n2.length)
            return NSOrderedDescending;
        if (n1.length < n2.length)
            return NSOrderedAscending;
        return NSOrderedSame;
    }];

    [_resultString appendFormat:@"// Properties\r\n"];
    for (NSString *propertyName in propertyNames) {
        [self generatePropertySymbols:propertyName];
    }
    [_resultString appendFormat:@"\r\n"];

    [_resultString appendFormat:@"// Protocols\r\n"];
    for (NSString *protocolName in _protocolNames) {
        [self generateSimpleSymbols:protocolName];
    }
    [_resultString appendFormat:@"\r\n"];

    [_resultString appendFormat:@"// Classes\r\n"];
    for (NSString *className in _classNames) {
        [self generateSimpleSymbols:className];
    }
    [_resultString appendFormat:@"\r\n"];

    [_resultString appendFormat:@"// Categories\r\n"];
    for (NSString *categoryName in _categoryNames) {
        [self generateSimpleSymbols:categoryName];
    }
    [_resultString appendFormat:@"\r\n"];

    [_resultString appendFormat:@"// Methods\r\n"];
    for (NSString *methodName in _methodNames) {
        [self generateMethodSymbols:methodName];
    }
    [_resultString appendFormat:@"\r\n"];

    [_resultString appendFormat:@"// I-vars\r\n"];
    for (NSString *ivarName in _ivarNames) {
        [self generateSimpleSymbols:ivarName];
    }
    [_resultString appendFormat:@"\r\n"];

    NSData *data = [_resultString dataUsingEncoding:NSUTF8StringEncoding];
    [(NSFileHandle *) [NSFileHandle fileHandleWithStandardOutput] writeData:data];

    NSLog(@"Done generating symbol table.");
    NSLog(@"Generated unique symbols = %zd", _uniqueSymbols.count);
}

- (NSString *)generateRandomStringWithLength:(NSInteger)length andPrefix:(NSString *)prefix {
    while (true) {
        NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
        if (prefix) {
            [randomString appendString:prefix];
        }

        for (int i = 0; i < length; i++) {
            NSString *letters = lettersSet[MIN(i, maxLettersSet - 1)];
            NSInteger index = arc4random_uniform((u_int32_t) letters.length);
            [randomString appendString:[letters substringWithRange:NSMakeRange(index, 1)]];
        }

        if ([_uniqueSymbols containsObject:randomString]) {
            ++length;
            continue;
        }

        return randomString;
    }
}

- (NSString *)generateRandomString {
    return [self generateRandomStringWithLength:_symbolLength andPrefix:nil];
}

- (NSString *)generateRandomStringWithPrefix:(NSString *)prefix {
    return [self generateRandomStringWithLength:_symbolLength andPrefix:prefix];
}

- (BOOL)doesContainGeneratedSymbol:(NSString *)symbol {
    return [_symbols objectForKey:symbol] != nil;
}

- (void)generateSimpleSymbols:(NSString *)symbolName {
    if ([self doesContainGeneratedSymbol:symbolName]) {
        return;
    }
    if ([self shouldSymbolsBeIgnored:symbolName]) {
        return;
    }
    NSString *newSymbolName = [self generateRandomString];
    [self addGenerated:newSymbolName forSymbol:symbolName];
}

- (bool)isInitMethod:(NSString *)symbolName {
    if (![symbolName hasPrefix:@"init"]) {
        return NO;
    }

    // just "init"
    if (symbolName.length == 4) {
        return YES;
    }

    // we expect that next character after init is in UPPER CASE
    if (isupper([symbolName characterAtIndex:4])) {
        return YES;
    }

    return NO;
}

- (void)generateMethodSymbols:(NSString *)symbolName {
    if ([self doesContainGeneratedSymbol:symbolName]) {
        return;
    }
    if ([self shouldSymbolsBeIgnored:symbolName]) {
        return;
    }
    if ([self isInitMethod:symbolName]) {
        NSString *newSymbolName = [self generateRandomStringWithPrefix:@"initL"];
        [self addGenerated:newSymbolName forSymbol:symbolName];
    } else {
        NSString *newSymbolName = [self generateRandomString];
        [self addGenerated:newSymbolName forSymbol:symbolName];
    }
}

- (NSString *)ivarPropertyName:(NSString *)propertyName {
    return [@"_" stringByAppendingString:propertyName];
}

- (NSString *)getterPropertyName:(NSString *)propertyName {
    return propertyName;
}

- (NSString *)setterPropertyName:(NSString *)propertyName {
    NSMutableString *setterName = [NSMutableString new];
    [setterName appendString:@"set"];
    [setterName appendString:[propertyName capitalizeFirstCharacter]];
    return setterName;
}

- (void)addGenerated:(NSString *)generatedSymbol forSymbol:(NSString *)symbol {
    [_uniqueSymbols addObject:generatedSymbol];
    [_symbols setObject:generatedSymbol forKey:symbol];

    [_resultString appendFormat:@"#ifndef %@\r\n", symbol];
    [_resultString appendFormat:@"#define %@ %@\r\n", symbol, generatedSymbol];
    [_resultString appendFormat:@"#endif // %@\r\n", symbol];
}

- (void)generatePropertySymbols:(NSString *)propertyName {
    NSString *ivarName = [self ivarPropertyName:propertyName];
    NSString *getterName = [self getterPropertyName:propertyName];
    NSString *setterName = [self setterPropertyName:propertyName];

    // don't generate symbol if any of the name is forbidden
    if ([self shouldSymbolsBeIgnored:ivarName] ||
            [self shouldSymbolsBeIgnored:getterName] ||
            [self shouldSymbolsBeIgnored:setterName]) {
        [_forbiddenNames addObject:ivarName];
        [_forbiddenNames addObject:getterName];
        [_forbiddenNames addObject:setterName];
        return;
    }

    NSString *newPropertyName = [_symbols objectForKey:propertyName];

    // reuse previously generated symbol
    if (newPropertyName) {
        NSString *newIvarName = [self ivarPropertyName:newPropertyName];
        NSString *newGetterName = [self getterPropertyName:newPropertyName];
        NSString *newSetterName = [self setterPropertyName:newPropertyName];
        [self addGenerated:newIvarName forSymbol:ivarName];
        [self addGenerated:newGetterName forSymbol:getterName];
        [self addGenerated:newSetterName forSymbol:setterName];
        return;
    }

    NSInteger symbolLength = _symbolLength;

    while (true) {
        newPropertyName = [self generateRandomStringWithLength:symbolLength andPrefix:nil];

        NSString *newIvarName = [self ivarPropertyName:newPropertyName];
        NSString *newGetterName = [self getterPropertyName:newPropertyName];
        NSString *newSetterName = [self setterPropertyName:newPropertyName];

        // check if symbol is already generated
        if (![_uniqueSymbols containsObject:newIvarName] &&
                ![_uniqueSymbols containsObject:newGetterName] &&
                ![_uniqueSymbols containsObject:newSetterName]) {

            [self addGenerated:newIvarName forSymbol:ivarName];
            [self addGenerated:newGetterName forSymbol:getterName];
            [self addGenerated:newSetterName forSymbol:setterName];
            return;
        }

        ++symbolLength;
    }
}

- (BOOL)shouldClassBeObfuscated:(NSString *)className {
    for (NSString *filter in self.classFilter) {
        if ([filter hasPrefix:@"!"]) {
            // negative filter - prefixed with !
            if ([className isLike:[filter substringFromIndex:1]]) {
                return NO;
            }
        } else {
            // positive filter
            if ([className isLike:filter]) {
                return YES;
            }
        }
    }

    if ([self shouldSymbolsBeIgnored:className]) {
        return NO;
    }
    return YES;
}

- (BOOL)shouldSymbolsBeIgnored:(NSString *)symbolName {
    if ([symbolName hasPrefix:@"."]) { // .cxx_destruct
        return YES;
    }

    if ([_forbiddenNames containsObject:symbolName]) {
        return YES;
    }

    for (NSString *filter in self.ignoreSymbols) {
        if ([symbolName isLike:filter]) {
            return YES;
        }
    }

    return NO;
}

#pragma mark - CDVisitor

- (void)willVisitObjectiveCProcessor:(CDObjectiveCProcessor *)processor {
    NSString *importBaseName = processor.machOFile.importBaseName;

    if (importBaseName) {
        NSLog(@"Processing external symbols from %@...", importBaseName);
        _external = YES;
    } else {
        NSLog(@"Processing internal symbols...");
        _external = NO;
    }
}

- (void)willVisitProtocol:(CDOCProtocol *)protocol {
    if (_external) {
        [_forbiddenNames addObject:protocol.name];
        _ignored = YES;
    } else if (![self shouldClassBeObfuscated:protocol.name]) {
        NSLog(@"Ignoring @protocol %@", protocol.name);
        [_forbiddenNames addObject:protocol.name];
        _ignored = YES;
    } else {
        NSLog(@"Obfuscating @protocol %@", protocol.name);
        [_protocolNames addObject:protocol.name];
        _ignored = NO;
    }
}

- (void)willVisitClass:(CDOCClass *)aClass {
    if (_external) {
        [_forbiddenNames addObject:aClass.name];

        if (![aClass.name hasSuffix:@"Delegate"] && ![aClass.name hasSuffix:@"Protocol"]) {
            [_forbiddenNames addObject:[aClass.name stringByAppendingString:@"Delegate"]];
            [_forbiddenNames addObject:[aClass.name stringByAppendingString:@"Protocol"]];
        }

        _ignored = YES;
    } else if (![self shouldClassBeObfuscated:aClass.name]) {
        NSLog(@"Ignoring @class %@", aClass.name);
        [_forbiddenNames addObject:aClass.name];
        _ignored = YES;
    } else {
        NSLog(@"Obfuscating @class %@", aClass.name);
        [_classNames addObject:aClass.name];
        _ignored = NO;

        if ([aClass.name isEqualToString:@"IKOCore"]) {
            NSLog(@"Found");
        }
    }
}

- (void)willVisitCategory:(CDOCCategory *)category {
    if (_external) {
        _ignored = YES;
    } else {
        NSLog(@"Obfuscating @category %@+%@", category.className, category.name);
        [_categoryNames addObject:category.name];
        _ignored = NO;
    }
}

- (void)visitClassMethod:(CDOCMethod *)method {
    [self visitAndExplodeMethod:method.name];
}

- (void)visitAndExplodeMethod:(NSString *)method {
    for (NSString *component in [method componentsSeparatedByString:@":"]) {
        if ([component length]) {
            if (_ignored) {
                [_forbiddenNames addObject:component];
            } else {
                [_methodNames addObject:component];
            }
        }
    }
}

- (void)visitInstanceMethod:(CDOCMethod *)method propertyState:(CDVisitorPropertyState *)propertyState {
    [self visitAndExplodeMethod:method.name];

//    if (!_ignored && [method.name rangeOfString:@":"].location == NSNotFound) {
//        [_propertyNames addObject:method.name];
//    }
}

- (void)visitIvar:(CDOCInstanceVariable *)ivar {
    if (_ignored) {
        [self visitType:ivar.type];
    } else {
        [_ivarNames addObject:ivar.name];
    }
}

- (void)visitProperty:(CDOCProperty *)property {
    if (_ignored) {
        [_forbiddenNames addObject:property.name];
        [_forbiddenNames addObject:property.defaultGetter];
        [_forbiddenNames addObject:[@"_" stringByAppendingString:property.name]];
        [_forbiddenNames addObject:property.defaultSetter];
        [self visitType:property.type];
    } else {
        [_propertyNames addObject:property.name];
    }
}

- (void)visitRemainingProperties:(CDVisitorPropertyState *)propertyState {
    for (CDOCProperty *property in propertyState.remainingProperties) {
        [self visitProperty:property];
    }
}

- (void)visitType:(CDType *)type {
    if (_ignored) {
        for (NSString *protocol in type.protocols) {
            [_forbiddenNames addObject:protocol];
        }

        if (type.typeName) {
            [_forbiddenNames addObject:[NSString stringWithFormat:@"%@", type.typeName]];
        }
    }
}

@end