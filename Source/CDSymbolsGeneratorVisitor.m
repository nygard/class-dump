#import "CDSymbolsGeneratorVisitor.h"
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

@implementation CDSymbolsGeneratorVisitor {
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
            @"bool",
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
            @"alloc",
            @"_inline",
            @"_Bool"
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
    [data writeToFile:self.symbolsFilePath atomically:YES];

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

- (NSString *)generateRandomStringWithLength:(NSUInteger)length {
    return [self generateRandomStringWithLength:length andPrefix:nil];
}

- (NSString *)generateRandomStringWithPrefix:(NSString *)prefix length:(NSUInteger)length {
    return [self generateRandomStringWithLength:length andPrefix:prefix];
}

- (BOOL)doesContainGeneratedSymbol:(NSString *)symbol {
    return _symbols[symbol] != nil;
}

- (void)generateSimpleSymbols:(NSString *)symbolName {
    if ([self doesContainGeneratedSymbol:symbolName]) {
        return;
    }
    if ([self shouldSymbolsBeIgnored:symbolName]) {
        return;
    }
    NSString *newSymbolName = [self generateRandomStringWithLength:symbolName.length];
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
    return isupper([symbolName characterAtIndex:4]) != 0;

}

- (NSString *)getterNameForMethodName:(NSString *)methodName {
    NSString *setterPrefix = @"set";
    BOOL hasSetterPrefix = [methodName hasPrefix:setterPrefix];
    BOOL isEqualToSetter = [methodName isEqualToString:setterPrefix];

    if (hasSetterPrefix && !isEqualToSetter) {
        BOOL isFirstLetterAfterPrefixUppercase = [[methodName substringFromIndex:setterPrefix.length] isFirstLetterUppercase];

        NSString *methodNameToObfuscate = methodName;

        // exclude method names like setupSomething
        if (isFirstLetterAfterPrefixUppercase) {
            methodNameToObfuscate = [methodName stringByReplacingCharactersInRange:NSMakeRange(0, setterPrefix.length) withString:@""];
        }

        if (![self shouldSymbolStartWithLowercase:methodNameToObfuscate]) {
            return methodNameToObfuscate;
        } else {
            return [methodNameToObfuscate lowercaseFirstCharacter];
        }
    } else {
        return methodName;
    }
}

- (BOOL)shouldSymbolStartWithLowercase:(NSString *)symbol {
    // if two first characters in symbol are uppercase name should not be changed to lowercase
    if (symbol.length > 1) {
        NSString *prefix = [symbol substringToIndex:2];
        if ([prefix isEqualToString:[prefix uppercaseString]]) {
            return NO;
        }
    } else if ([symbol isEqualToString:[symbol uppercaseString]]) {
        return NO;
    }
    return YES;
}

- (NSString *)setterNameForMethodName:(NSString *)methodName {
    NSString *setterPrefix = @"set";
    BOOL hasSetterPrefix = [methodName hasPrefix:setterPrefix];
    BOOL isEqualToSetter = [methodName isEqualToString:setterPrefix];

    if (hasSetterPrefix && !isEqualToSetter) {
        BOOL isFirstLetterAfterPrefixUppercase = [[methodName substringFromIndex:setterPrefix.length] isFirstLetterUppercase];
        // Excludes methods like setupSomething
        if (isFirstLetterAfterPrefixUppercase) {
            return methodName;
        } else {
            return [setterPrefix stringByAppendingString:[methodName capitalizeFirstCharacter]];
        }
    } else {
        return [setterPrefix stringByAppendingString:[methodName capitalizeFirstCharacter]];
    }
}

- (void)generateMethodSymbols:(NSString *)symbolName {
    NSString *getterName = [self getterNameForMethodName:symbolName];
    NSString *setterName = [self setterNameForMethodName:symbolName];

    if ([self doesContainGeneratedSymbol:getterName] && [self doesContainGeneratedSymbol:setterName]) {
        return;
    }
    if ([self shouldSymbolsBeIgnored:getterName] || [self shouldSymbolsBeIgnored:setterName]) {
        return;
    }
    if ([self isInitMethod:symbolName]) {
        NSString *initPrefix = @"initL";
        NSString *newSymbolName = [self generateRandomStringWithPrefix:initPrefix length:symbolName.length - initPrefix.length];
        [self addGenerated:newSymbolName forSymbol:symbolName];
    } else {
        NSString *newSymbolName = [self generateRandomStringWithLength:symbolName.length];
        [self addGenerated:newSymbolName forSymbol:getterName];
        [self addGenerated:[@"set" stringByAppendingString:[newSymbolName capitalizeFirstCharacter]] forSymbol:setterName];
    }
}

- (NSString *)plainIvarPropertyName:(NSString *)propertyName {
    return [@"_" stringByAppendingString:[self plainGetterName:propertyName]];
}

- (NSString *)isIvarPropertyName:(NSString *)propertyName {
    return [@"_" stringByAppendingString:[self isGetterName:propertyName]];
}

- (NSString *)plainGetterName:(NSString *)propertyName {
    if ([propertyName hasPrefix:@"is"] && ![propertyName isEqualToString:@"is"]) {
        NSString *string = [propertyName stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:@""];
        // If property name is all upper case then don't change first letter to lower case e.g. URL should remain URL, not uRL
        if (![self shouldSymbolStartWithLowercase:string]) {
            return string;
        } else {
            return [string lowercaseFirstCharacter];
        }
    } else if (![self shouldSymbolStartWithLowercase:propertyName]){
        return propertyName;
    } else {
        return [propertyName lowercaseFirstCharacter];
    }
}

- (NSString *)isGetterName:(NSString *)propertyName {
    if ([propertyName hasPrefix:@"is"] && ![propertyName isEqualToString:@"is"]) {
        return propertyName;
    } else {
        return [@"is" stringByAppendingString:[propertyName capitalizeFirstCharacter]];
    }
}

- (NSString *)plainSetterPropertyName:(NSString *)propertyName {
    return [@"set" stringByAppendingString:[[self plainGetterName:propertyName] capitalizeFirstCharacter]];
}

- (NSString *)isSetterPropertyName:(NSString *)propertyName {
    return [@"set" stringByAppendingString:[[self isGetterName:propertyName] capitalizeFirstCharacter]];
}

- (void)addGenerated:(NSString *)generatedSymbol forSymbol:(NSString *)symbol {
    [_uniqueSymbols addObject:generatedSymbol];
    _symbols[symbol] = generatedSymbol;

    [_resultString appendFormat:@"#ifndef %@\r\n", symbol];
    [_resultString appendFormat:@"#define %@ %@\r\n", symbol, generatedSymbol];
    [_resultString appendFormat:@"#endif // %@\r\n", symbol];
}

- (void)generatePropertySymbols:(NSString *)propertyName {
    NSArray *symbols = [self symbolsForProperty:propertyName];
    BOOL shouldSymbolBeIgnored = NO;
    for (NSString *symbolName in symbols) {
        if ([self shouldSymbolsBeIgnored:symbolName]) {
            shouldSymbolBeIgnored = YES;
            break;
        }
    }

    // don't generate symbol if any of the name is forbidden
    if (shouldSymbolBeIgnored) {
        [_forbiddenNames addObjectsFromArray:symbols];
        return;
    }

    NSString *newPropertyName = _symbols[propertyName];

    // reuse previously generated symbol
    if (newPropertyName) {
        NSDictionary *symbolMapping = [self symbolMappingForOriginalPropertyName:propertyName generatedPropertyName:newPropertyName];
        for (NSString *key in symbolMapping.allKeys) {
            [self addGenerated:symbolMapping[key] forSymbol:key];
        }
        return;
    }

    [self createNewSymbolsForProperty:propertyName];

}

- (void)createNewSymbolsForProperty:(NSString *)propertyName {
    NSInteger symbolLength = propertyName.length;

    while (true) {
        NSString *newPropertyName = [self generateRandomStringWithLength:symbolLength andPrefix:nil];
        NSArray *symbols = [self symbolsForProperty:newPropertyName];

        BOOL isAlreadyGenerated = NO;
        for (NSString *symbolName in symbols) {
            if ([_uniqueSymbols containsObject:symbolName]) {
                isAlreadyGenerated = YES;
                break;
            }
        }
        // check if symbol is already generated
        if (!isAlreadyGenerated) {
            NSDictionary *symbolMapping = [self symbolMappingForOriginalPropertyName:propertyName generatedPropertyName:newPropertyName];
            for (NSString *key in symbolMapping.allKeys) {
                [self addGenerated:symbolMapping[key] forSymbol:key];
            }
            return;
        }

        ++symbolLength;
    }
}

- (NSDictionary *)symbolMappingForOriginalPropertyName:(NSString *)originalPropertyName generatedPropertyName:(NSString *)generatedName {
    NSString *ivarName = [self plainIvarPropertyName:originalPropertyName];
    NSString *isIvarName = [self isIvarPropertyName:originalPropertyName];
    NSString *getterName = [self plainGetterName:originalPropertyName];
    NSString *isGetterName = [self isGetterName:originalPropertyName];
    NSString *setterName = [self plainSetterPropertyName:originalPropertyName];
    NSString *isSetterName = [self isSetterPropertyName:originalPropertyName];

    NSString *newIvarName = [self plainIvarPropertyName:generatedName];
    NSString *newIsIvarName = [self isIvarPropertyName:generatedName];
    NSString *newGetterName = [self plainGetterName:generatedName];
    NSString *newIsGetterName = [self isGetterName:generatedName];
    NSString *newSetterName = [self plainSetterPropertyName:generatedName];
    NSString *newIsSetterName = [self isSetterPropertyName:generatedName];

    return @{ivarName : newIvarName,
            isIvarName : newIsIvarName,
            getterName : newGetterName,
            isGetterName : newIsGetterName,
            setterName : newSetterName,
            isSetterName : newIsSetterName};
}

- (NSArray *)symbolsForProperty:(NSString *)propertyName {
    NSString *ivarName = [self plainIvarPropertyName:propertyName];
    NSString *isIvarName = [self isIvarPropertyName:propertyName];
    NSString *getterName = [self plainGetterName:propertyName];
    NSString *isGetterName = [self isGetterName:propertyName];
    NSString *setterName = [self plainSetterPropertyName:propertyName];
    NSString *isSetterName = [self isSetterPropertyName:propertyName];

    NSMutableArray *symbols = [NSMutableArray arrayWithObject:ivarName];
    [symbols addObject:isIvarName];
    [symbols addObject:getterName];
    [symbols addObject:isGetterName];
    [symbols addObject:setterName];
    [symbols addObject:isSetterName];
    return symbols;
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

    return ![self shouldSymbolsBeIgnored:className];
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

- (void)addSymbolsPadding {
    [_symbols.allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        NSString *obfuscated = _symbols[key];
        if (key.length > obfuscated.length) {
            _symbols[key] = [self generateRandomStringWithLength:key.length - obfuscated.length andPrefix:obfuscated];
        }
    }];
}

@end
