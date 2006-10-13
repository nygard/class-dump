//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2005  Steve Nygard

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

- (void)testType:(NSString *)aType showLexing:(BOOL)shouldShowLexing;
{
    CDTypeParser *aTypeParser;
    CDType *result;

    aTypeParser = [[CDTypeParser alloc] initWithType:aType];
    [[aTypeParser lexer] setShouldShowLexing:shouldShowLexing];
    result = [aTypeParser parseType];
    NSLog(@"result: %p", result);
    [self assertNotNil:result];
    [aTypeParser release];
}

// In all of this mess, we test empty quoted strings.
// ^{IPPhotoList=^^?{vector<IPPhotoInfo*,std::allocator<IPPhotoInfo*> >=""{?=""{?="_M_start"^^{IPPhotoInfo}"_M_finish"^^{IPPhotoInfo}"_M_end_of_storage"^^{IPPhotoInfo}}}}{_opaque_pthread_mutex_t="sig"l"opaque"[40c]}}

- (void)test2;
{
    NSString *str = @"^{IPPhotoList=^^?{vector<IPPhotoInfo*,std::allocator<IPPhotoInfo*> >=\"\"{?=\"\"{?=\"_M_start\"^^{IPPhotoInfo}\"_M_finish\"^^{IPPhotoInfo}\"_M_end_of_storage\"^^{IPPhotoInfo}}}}{_opaque_pthread_mutex_t=\"sig\"l\"opaque\"[40c]}}";

    [self testType:str showLexing:NO];
}

// ^{IPAlbumList=^^?{vector<Album*,std::allocator<Album*> >=""{?=""{?="_M_start"^@"Album""_M_finish"^@"Album""_M_end_of_storage"^@"Album"}}}{_opaque_pthread_mutex_t="sig"l"opaque"[40c]}}

- (void)test3;
{
    NSString *str = @"^{IPAlbumList=^^?{vector<Album*,std::allocator<Album*> >=\"\"{?=\"\"{?=\"_M_start\"^@\"Album\"\"_M_finish\"^@\"Album\"\"_M_end_of_storage\"^@\"Album\"}}}{_opaque_pthread_mutex_t=\"sig\"l\"opaque\"[40c]}}";

    NSLog(@"str: %@", str);
    [self testType:str showLexing:YES];
}

@end
