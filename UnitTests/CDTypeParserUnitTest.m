//
// $Id: CDTypeParserUnitTest.m,v 1.3 2004/01/18 02:30:09 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

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

- (void)test1;
{
    // On Panther, from WebCore, -[KWQPageState
    // initWithDocument:URL:windowProperties:locationProperties:interpreterBuiltins:]
    // has part of a method type as "r12".  "r" is const, but it doesn't modify anything.

    [self testMethodType:@"ri12i16" showLexing:NO]; // This works
    [self testMethodType:@"r12i16" showLexing:YES]; // This doesn't work.
}

@end
