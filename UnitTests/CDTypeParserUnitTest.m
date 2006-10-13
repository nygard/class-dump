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

    NSLog(@"----------------------------------------");
    NSLog(@"str: %@", aType);
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

// If the next token is not a type, use the quoted string as the object type.
// Grr.  Need to know if this structure is using field names or not.

// Field names:
// {?="field1"^@"NSObject"} -- end of struct, use quoted string
// {?="field1"^@"NSObject""field2"@} -- followed by field, use quoted string
// {?="field1"^@"field2"^@} -- quoted string is followed by type, don't use quoted string for object

// No field names -- always use the quoted string
// {?=^@"NSObject"}
// {?=^@"NSObject"^@"NSObject"}

- (void)test3;
{
    //NSString *str = @"^{IPAlbumList=^^?{vector<Album*,std::allocator<Album*> >=\"\"{?=\"\"{?=\"_M_start\"^@\"Album\"\"_M_finish\"^@\"Album\"\"_M_end_of_storage\"^@\"Album\"}}}{_opaque_pthread_mutex_t=\"sig\"l\"opaque\"[40c]}}";
    NSString *str = @"{?=\"field1\"^@\"NSObject\"}";

    str = @"{?=\"field1\"^@\"NSObject\"}";
    [self testType:str showLexing:YES];

    str = @"{?=\"field1\"^@\"NSObject\"\"field2\"@}";
    [self testType:str showLexing:YES];

    str = @"{?=\"field1\"^@\"field2\"^@}";
    [self testType:str showLexing:YES];

    str = @"{?=^@\"NSObject\"}";
    [self testType:str showLexing:YES];

    str = @"{?=^@\"NSObject\"^@\"NSObject\"}";
    [self testType:str showLexing:YES];
}

@end
