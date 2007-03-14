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
    BOOL result;

    fileManager = [NSFileManager defaultManager];
    fileAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0700], NSFilePosixPermissions,
                                       nil];

    result = [fileManager createDirectoryAtPath:[@"~/tmp" stringByExpandingTildeInPath] attributes:fileAttributes];
    result = [fileManager createDirectoryAtPath:[@"~/tmp/ClassDumpTest" stringByExpandingTildeInPath] attributes:fileAttributes];
    result = [fileManager createDirectoryAtPath:[@"~/tmp/ClassDumpTest/out" stringByExpandingTildeInPath] attributes:fileAttributes];
    result = [fileManager removeFileAtPath:[@"~/tmp/ClassDumpTest/Foundation.framework" stringByExpandingTildeInPath] handler:nil];
    result = [fileManager createSymbolicLinkAtPath:[@"~/tmp/ClassDumpTest/Foundation.framework" stringByExpandingTildeInPath]
                          pathContent:@"/System/Library/Frameworks/Foundation.framework"];
}

- (void)tearDown;
{
}

- (void)_testPath:(NSString *)sourcePath expectedResult:(NSString *)expectedResult;
{
    NSString *result;

    result = [CDClassDump adjustUserSuppliedPath:sourcePath];
    [self assert:result equals:expectedResult];
}

- (void)testPaths;
{
    [self _testPath:@"/System/Library/Frameworks/Foundation.framework/Foundation"
          expectedResult:@"/System/Library/Frameworks/Foundation.framework/Versions/C/Foundation"];
    [self _testPath:@"/System/Library/Frameworks/Foundation.framework"
          expectedResult:@"/System/Library/Frameworks/Foundation.framework/Versions/C/Foundation"];
    [self _testPath:@"~/tmp/ClassDumpTest/Foundation.framework"
          expectedResult:@"~/tmp/ClassDumpTest/Foundation.framework/Versions/C/Foundation"];
}

- (void)testDotDot;
{
    BOOL result;

    result = [[NSFileManager defaultManager] changeCurrentDirectoryPath:[@"~/tmp/ClassDumpTest/out" stringByExpandingTildeInPath]];
    [self assertTrue:result message:@"Change director to ~/tmp/ClassDumpTest/out"];

    [self _testPath:@"../Foundation.framework"
          expectedResult:@"../Foundation.framework/Versions/C/Foundation"];
}

@end
