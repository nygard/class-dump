#import "CDTypeLexer.h"

#import <Foundation/Foundation.h>
//#include "gram.h" // for TK_IDENTIFIER
#import "NSScanner-Extensions.h"

@implementation CDTypeLexer

- (id)initWithString:(NSString *)aString;
{
    NSCharacterSet *otherCharacterSet;
    NSMutableCharacterSet *aSet;

    if ([super init] == nil)
        return nil;

    scanner = [[NSScanner alloc] initWithString:aString];
    [scanner setCharactersToBeSkipped:nil];
    isInIdentifierState = NO;

    // other: $_:*
    // start: alpha + other
    // remainder: alnum + other

    otherCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"$_:*"];

    aSet = [[NSCharacterSet letterCharacterSet] mutableCopy];

    [aSet formUnionWithCharacterSet:otherCharacterSet];
    identifierStartSet = [aSet copy];

    [aSet formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    identifierSet = [aSet copy];

    [aSet release];

    return self;
}

- (void)dealloc;
{
    [scanner release];
    [lexText release];
    [identifierStartSet release];
    [identifierSet release];

    [super dealloc];
}

- (BOOL)isInIdentifierState;
{
    return isInIdentifierState;
}

- (void)setIsInIdentifierState:(BOOL)newFlag;
{
    isInIdentifierState = newFlag;
}

// TODO: Change to scanNextToken?
- (int)nextToken;
{
    NSString *str;
    unichar ch;

    [self _setLexText:nil];

    if ([scanner isAtEnd] == YES)
        return 0;

    if (isInIdentifierState == YES) {
        NSString *start, *remainder;

        //NSLog(@"Scanning in identifier state.");

        if ([scanner scanString:@"?" intoString:NULL] == YES) {
            [self _setLexText:@"?"];
            return TK_IDENTIFIER;
        }

        if ([scanner scanString:@"\"" intoString:NULL] == YES) {
            [self setIsInIdentifierState:NO];
            return '"';
        }

        if ([scanner scanCharacterFromSet:identifierStartSet intoString:&start] == YES) {
            if ([scanner scanCharactersFromSet:identifierSet intoString:&remainder] == YES) {
                str = [start stringByAppendingString:remainder];
            } else {
                str = start;
            }

            [self setIsInIdentifierState:NO];
            [self _setLexText:str];
            return TK_IDENTIFIER;
        }
    }

    if ([scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&str] == YES) {
        [self _setLexText:str];
        return TK_NUMBER;
    }

    if ([scanner scanCharacter:&ch] == YES) {
        // TODO: I'm just assuming this works.
        return ch;
    }

    return 0;
}

- (NSString *)lexText;
{
    return lexText;
}

- (void)_setLexText:(NSString *)newString;
{
    if (newString == lexText)
        return;

    [lexText release];
    lexText = [newString retain];
}

@end
