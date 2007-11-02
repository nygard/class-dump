//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDPathUnitTest.h"

#import <Foundation/Foundation.h>
#import "CDClassDump.h"

@implementation CDPathUnitTest

- (void)setUp;
{
    NSFileManager *fileManager;
    NSDictionary *fileAttributes;

    fileManager = [NSFileManager defaultManager];
    fileAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0700], NSFilePosixPermissions,
                                       nil];

    [fileManager createDirectoryAtPath:[@"~/tmp" stringByExpandingTildeInPath] attributes:fileAttributes];
    [fileManager createDirectoryAtPath:[@"~/tmp/ClassDumpTest" stringByExpandingTildeInPath] attributes:fileAttributes];
    [fileManager createDirectoryAtPath:[@"~/tmp/ClassDumpTest/out" stringByExpandingTildeInPath] attributes:fileAttributes];
    [fileManager removeFileAtPath:[@"~/tmp/ClassDumpTest/Foundation.framework" stringByExpandingTildeInPath] handler:nil];
    [fileManager createSymbolicLinkAtPath:[@"~/tmp/ClassDumpTest/Foundation.framework" stringByExpandingTildeInPath]
                 pathContent:@"/System/Library/Frameworks/Foundation.framework"];
}

- (void)tearDown;
{
    NSFileManager *fileManager;

    fileManager = [NSFileManager defaultManager];

    // This is recursive.  Kind of scary with the ~.
    [fileManager removeFileAtPath:[@"~/tmp/ClassDumpTest" stringByExpandingTildeInPath] handler:nil];
}

- (void)_testPath:(NSString *)sourcePath expectedResult:(NSString *)expectedResult;
{
    NSString *result;

    result = [CDClassDump adjustUserSuppliedPath:sourcePath];
    NSLog(@"----------------------------------------");
    NSLog(@"input: %@", sourcePath);
    NSLog(@"expected result: %@", expectedResult);
    NSLog(@"actual result:   %@", result);
    NSLog(@"result: %@", result);
    STAssertEqualObjects(expectedResult, result, @"Expected result didn't match result...");
    //[self assert:result equals:expectedResult];
}

- (void)testPaths;
{
    [self _testPath:@"/System/Library/Frameworks/Foundation.framework/Foundation"
          expectedResult:@"/System/Library/Frameworks/Foundation.framework/Versions/C/Foundation"];
#if 0
    [self _testPath:@"/System/Library/Frameworks/Foundation.framework"
          expectedResult:@"/System/Library/Frameworks/Foundation.framework/Versions/C/Foundation"];
    [self _testPath:@"~/tmp/ClassDumpTest/Foundation.framework"
          expectedResult:@"~/tmp/ClassDumpTest/Foundation.framework/Versions/C/Foundation"];
#endif
}

- (void)testDotDot;
{
#if 0
    BOOL result;

    result = [[NSFileManager defaultManager] changeCurrentDirectoryPath:[@"~/tmp/ClassDumpTest/out" stringByExpandingTildeInPath]];
    //[self assertTrue:result message:@"Change directory to ~/tmp/ClassDumpTest/out"];

    [self _testPath:@"../Foundation.framework"
          expectedResult:@"../Foundation.framework/Versions/C/Foundation"];
#endif
}

@end
