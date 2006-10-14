//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2006  Steve Nygard

#import "CDTypeParserUnitTest.h"

#import <Foundation/Foundation.h>
#import "CDType.h"
#import "CDTypeLexer.h"
#import "CDTypeParser.h"

@implementation CDTypeParserUnitTest

- (void)setUp;
{
}

- (void)tearDown;
{
}

- (void)testType:(NSString *)aType showLexing:(BOOL)shouldShowLexing;
{
    CDTypeParser *aTypeParser;
    CDType *result;

    if (shouldShowLexing) {
        NSLog(@"----------------------------------------");
        NSLog(@"str: %@", aType);
    }

    aTypeParser = [[CDTypeParser alloc] initWithType:aType];
    [[aTypeParser lexer] setShouldShowLexing:shouldShowLexing];
    result = [aTypeParser parseType];
    [self assertNotNil:result];
    [aTypeParser release];
}

- (void)testMethodType:(NSString *)aMethodType showLexing:(BOOL)shouldShowLexing;
{
    CDTypeParser *aTypeParser;
    NSArray *result;

    aTypeParser = [[CDTypeParser alloc] initWithType:aMethodType];
    [[aTypeParser lexer] setShouldShowLexing:shouldShowLexing];
    result = [aTypeParser parseMethodType];
    [self assertNotNil:result];
    [aTypeParser release];
}

- (void)testLoneConstType;
{
    // On Panther, from WebCore, -[KWQPageState
    // initWithDocument:URL:windowProperties:locationProperties:interpreterBuiltins:]
    // has part of a method type as "r12".  "r" is const, but it doesn't modify anything.

    [self testMethodType:@"ri12i16" showLexing:NO]; // This works
    [self testMethodType:@"r12i16" showLexing:NO]; // This didn't work.
}

// Field names:
// {?="field1"^@"NSObject"} -- end of struct, use quoted string
// {?="field1"^@"NSObject""field2"@} -- followed by field, use quoted string
// {?="field1"^@"field2"^@} -- quoted string is followed by type, don't use quoted string for object

// No field names -- always use the quoted string
// {?=^@"NSObject"}
// {?=^@"NSObject"^@"NSObject"}

- (void)testObjectQuotedStringTypes;
{
    NSString *str = @"{?=\"field1\"^@\"NSObject\"}";

    str = @"{?=\"field1\"^@\"NSObject\"}";
    [self testType:str showLexing:NO];

    str = @"{?=\"field1\"^@\"NSObject\"\"field2\"@}";
    [self testType:str showLexing:NO];

    str = @"{?=\"field1\"^@\"field2\"^@}";
    [self testType:str showLexing:NO];

    str = @"{?=^@\"NSObject\"}";
    [self testType:str showLexing:NO];

    str = @"{?=^@\"NSObject\"^@\"NSObject\"}";
    [self testType:str showLexing:NO];
}

@end
