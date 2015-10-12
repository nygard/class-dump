// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import <XCTest/XCTest.h>

#import "CDType.h"
#import "CDTypeName.h"

@interface CDType (UnitTests)
- (NSString *)blockSignatureString;
@end

@interface TestBlockSignature : XCTestCase
@end

@implementation TestBlockSignature

- (void)testZeroArguments;
{
	NSMutableArray *types = [NSMutableArray new];
	[types addObject:[[CDType alloc] initSimpleType:'v']];
	[types addObject:[[CDType alloc] initBlockTypeWithTypes:nil]];
	CDType *blockType = [[CDType alloc] initBlockTypeWithTypes:types];
	NSString *blockSignatureString = [blockType blockSignatureString];
	XCTAssertEqualObjects(blockSignatureString, @"void (^)(void)", @"");
}

- (void)testOneArgument;
{
	NSMutableArray *types = [NSMutableArray new];
	[types addObject:[[CDType alloc] initSimpleType:'v']];
	[types addObject:[[CDType alloc] initBlockTypeWithTypes:nil]];
	CDTypeName *typeName = [CDTypeName new];
	typeName.name = @"NSData";
	[types addObject:[[CDType alloc] initIDType:typeName]];
	CDType *blockType = [[CDType alloc] initBlockTypeWithTypes:types];
	NSString *blockSignatureString = [blockType blockSignatureString];
	XCTAssertEqualObjects(blockSignatureString, @"void (^)(NSData *)", @"");
}

- (void)testTwoArguments;
{
	NSMutableArray *types = [NSMutableArray new];
	[types addObject:[[CDType alloc] initSimpleType:'v']];
	[types addObject:[[CDType alloc] initBlockTypeWithTypes:nil]];
	[types addObject:[[CDType alloc] initIDType:nil]];
	CDTypeName *typeName = [CDTypeName new];
	typeName.name = @"NSError";
	[types addObject:[[CDType alloc] initIDType:typeName]];
	CDType *blockType = [[CDType alloc] initBlockTypeWithTypes:types];
	NSString *blockSignatureString = [blockType blockSignatureString];
	XCTAssertEqualObjects(blockSignatureString, @"void (^)(id, NSError *)", @"");
}

- (void)testBlockArgument;
{
	NSMutableArray *types = [NSMutableArray new];
	[types addObject:[[CDType alloc] initSimpleType:'v']];
	[types addObject:[[CDType alloc] initBlockTypeWithTypes:nil]];
	[types addObject:[[CDType alloc] initBlockTypeWithTypes:[types copy]]];
	CDType *blockType = [[CDType alloc] initBlockTypeWithTypes:types];
	NSString *blockSignatureString = [blockType blockSignatureString];
	XCTAssertEqualObjects(blockSignatureString, @"void (^)(void (^)(void))", @"");
}

- (void)testBOOLArgument;
{
	NSMutableArray *types = [NSMutableArray new];
	[types addObject:[[CDType alloc] initSimpleType:'v']];
	[types addObject:[[CDType alloc] initBlockTypeWithTypes:nil]];
	[types addObject:[[CDType alloc] initSimpleType:'c']];
	CDType *blockType = [[CDType alloc] initBlockTypeWithTypes:types];
	NSString *blockSignatureString = [blockType blockSignatureString];
	XCTAssertEqualObjects(blockSignatureString, @"void (^)(BOOL)", @"");
}

@end
