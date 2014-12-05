//
//  CDdSYMProcessor.m
//  ios-class-guard
//
//  Created by Tomasz Grynfelder on 22/01/15.
//  Copyright (c) 2015 Polidea Sp. z o.o. All rights reserved.
//
#import "CDdSYMProcessor.h"
#include "ahocorasick.h"

@implementation CDdSYMProcessor

- (NSData *)processDwarfdump:(NSData *)dwarfdumpContent withSymbols:(NSDictionary *)symbols {
    NSUInteger contentPseudoStringLength = dwarfdumpContent.length / sizeof(char);
    AC_ALPHABET_t *contentPseudoString = (char *)malloc(contentPseudoStringLength * sizeof(char));
    if (contentPseudoString == NULL) {
        printf("Not enough memory to process dwarfdump file.\n");
        exit(-1);
    }

    {
        char *begin = (char *)dwarfdumpContent.bytes;
        NSUInteger idx = 0;
        for (char *itr = begin; itr < begin + dwarfdumpContent.length; ++itr, ++idx) {
            contentPseudoString[idx] = *itr;
        }
    }

    AC_ALPHABET_t **patterns;
    NSUInteger patternsCount = symbols.count;
    patterns = (char **)malloc(patternsCount * sizeof(char*));
    if (patterns == NULL) {
        printf("Not enough memory to process dwarfdump file.\n");
        exit(-1);
    }

    NSArray *keys = [symbols allKeys];
    for (NSUInteger idx = 0; idx < patternsCount; ++idx) {
        patterns[idx] = (AC_ALPHABET_t *)[keys[idx] cStringUsingEncoding:NSASCIIStringEncoding];
    }

    AC_AUTOMATA_t *atm;
    AC_PATTERN_t tmpPattern;
    AC_TEXT_t tmpText;

    atm = ac_automata_init();

    for (NSUInteger idx = 0; idx < patternsCount; ++idx) {
        tmpPattern.astring = patterns[idx];
        tmpPattern.length = (unsigned int)strlen(tmpPattern.astring);

        ac_automata_add(atm, &tmpPattern);
    }

    ac_automata_finalize(atm);

    tmpText.astring = contentPseudoString;
    tmpText.length = (unsigned int)contentPseudoStringLength;
    ac_automata_settext(atm, &tmpText, 0);

    NSMutableDictionary *replaces = [[NSMutableDictionary alloc] init];

    AC_MATCH_t *matchPattern;
    while ((matchPattern = ac_automata_findnext(atm))) {
        NSUInteger maxStringIdx = 0, maxStringLength = 0;
        for (NSUInteger idx = 0; idx < matchPattern->match_num; ++idx) {
            // always take the longest string
            if (matchPattern->patterns[idx].length > maxStringLength) {
                maxStringIdx = idx;
                maxStringLength = matchPattern->patterns[idx].length;
            }
        }

        NSString *pattern = [[NSString alloc] initWithBytes:matchPattern->patterns[maxStringIdx].astring
                                                     length:matchPattern->patterns[maxStringIdx].length * sizeof(char)
                                                   encoding:NSASCIIStringEncoding
        ];
        NSNumber *position = @(matchPattern->position - matchPattern->patterns[maxStringIdx].length);
        replaces[pattern] = (replaces[pattern]
                ? [replaces[pattern] arrayByAddingObject:position]
                : @[position]
        );
    }

    ac_automata_release(atm);

    // TODO: exclude visited ranges
    for (NSString *pattern in replaces.allKeys) {
        for (NSNumber *position in replaces[pattern]) {
            [self replaceSymbol:pattern withSymbol:symbols[pattern] inPseudoCString:&contentPseudoString onPosition:[position unsignedIntegerValue]];
        }
    }

    NSData *dwarfdumpTranslatedContent = [[NSData alloc] initWithBytes:contentPseudoString
                                                                length:contentPseudoStringLength * sizeof(char)];
    free(patterns);
    free(contentPseudoString);

    return dwarfdumpTranslatedContent;
}

- (void)replaceSymbol:(NSString *)fromSymbol withSymbol:(NSString *)toSymbol inPseudoCString:(char **)contentPseudoCString onPosition:(NSUInteger)position {
    char *pseudoCString = *contentPseudoCString;
    NSUInteger finalSymbolLength = (toSymbol.length >= fromSymbol.length ? toSymbol.length : fromSymbol.length);
    char const *toSymbolCStr = [toSymbol cStringUsingEncoding:NSASCIIStringEncoding];

    // TODO: add check if right symbol is going to be changed
    for (NSUInteger location = 0; location < finalSymbolLength; ++location) {
        pseudoCString[position+location] = (location < toSymbol.length ? toSymbolCStr[location] : (char)'\0'); // if fromSymbol is longer than toSymbol - we're adding binary zeros
    }
}

- (void)writeDwarfdump:(NSData *)dwarfdumpContent originalDwarfPath:(NSString *)originalDwarfPath inputDSYM:(NSString *)inputDSYM outputDSYM:(NSString *)outputDSYM {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSRange dSYMPathRange = [originalDwarfPath rangeOfString:inputDSYM];
    NSString *dwarfPathInsideDSYM = [originalDwarfPath substringWithRange:(NSRange){
            dSYMPathRange.location + dSYMPathRange.length,
            originalDwarfPath.length - dSYMPathRange.length
    }];

    NSRange dSYMWithoutExtensionRange = [inputDSYM rangeOfString:@".dSYM" options:NSBackwardsSearch];
    NSString *deobfuscatedDSYM = (outputDSYM.length
            ? outputDSYM
            : [[originalDwarfPath substringWithRange:(NSRange){ 0, dSYMWithoutExtensionRange.location }] stringByAppendingString:@"_deobfuscated.dSYM"]
    );

    if (![fileManager fileExistsAtPath:deobfuscatedDSYM]) {
        NSError *error;
        [fileManager copyItemAtPath:inputDSYM toPath:deobfuscatedDSYM error:&error];
        if (error) {
            fprintf(stderr, "class-dump: unable to copy %s into output %s", [inputDSYM fileSystemRepresentation], [deobfuscatedDSYM fileSystemRepresentation]);
            exit(4);
        }
    }

    if (![dwarfdumpContent writeToFile:[deobfuscatedDSYM stringByAppendingPathComponent:dwarfPathInsideDSYM] atomically:YES]) {
        fprintf(stderr, "class-dump: unable to write result into %s", [[deobfuscatedDSYM stringByAppendingPathComponent:dwarfPathInsideDSYM] fileSystemRepresentation]);
        exit(4);
    }
}

- (NSArray *)extractDwarfPathsForDSYM:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *furtherPath = [self checkPathCorrectness:path requiredPathComponent:@"Contents" fileManager:fileManager];
    if (!furtherPath) {
        return nil;
    }

    furtherPath = [self checkPathCorrectness:furtherPath requiredPathComponent:@"Resources" fileManager:fileManager];
    if (!furtherPath) {
        return nil;
    }

    furtherPath = [self checkPathCorrectness:furtherPath requiredPathComponent:@"DWARF" fileManager:fileManager];
    if (!furtherPath) {
        return nil;
    }

    NSError *error;
    NSArray *dwarfdumpFiles = [fileManager contentsOfDirectoryAtPath:furtherPath error:&error];
    if (error) {
        return nil;
    }

    NSMutableArray *dwarfdumpPaths = [NSMutableArray arrayWithCapacity:dwarfdumpFiles.count];
    for (NSString *file in dwarfdumpFiles) {
        [dwarfdumpPaths addObject:[furtherPath stringByAppendingPathComponent:file]];
    }

    return dwarfdumpPaths;
}

- (NSString *)checkPathCorrectness:(NSString *)path requiredPathComponent:(NSString *)requiredComponent fileManager:(NSFileManager *)fileManager {
    NSError *error;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:path error:&error];
    if (error) {
        return nil;
    }

    NSUInteger index = [contents indexOfObjectPassingTest:^BOOL(NSString *element, NSUInteger idx, BOOL *stop) {
        return [element isEqualToString:requiredComponent];
    }];
    if (index == NSNotFound) {
        return nil;
    }

    return [path stringByAppendingPathComponent:requiredComponent];
}

@end
