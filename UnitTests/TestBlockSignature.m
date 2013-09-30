// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2013 Steve Nygard.

#import "TestBlockSignature.h"

#import "CDType.h"
#import "CDTypeName.h"

@interface CDType (UnitTests)
- (NSString *)blockSignatureString;
@end

@implementation TestBlockSignature

- (void)testZeroArguments;
{
	NSMutableArray *types = [NSMutableArray new];
	[types addObject:[[CDType alloc] initSimpleType:'v']];
	[types addObject:[[CDType alloc] initBlockTypeWithTypes:nil]];
	CDType *blockType = [[CDType alloc] initBlockTypeWithTypes:types];
	NSString *blockSignatureString = [blockType blockSignatureString];
	STAssertEqualObjects(blockSignatureString, @"void (^)(void)", nil);
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
	STAssertEqualObjects(blockSignatureString, @"void (^)(NSData *)", nil);
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
	STAssertEqualObjects(blockSignatureString, @"void (^)(id, NSError *)", nil);
}

- (void)testBlockArgument;
{
	NSMutableArray *types = [NSMutableArray new];
	[types addObject:[[CDType alloc] initSimpleType:'v']];
	[types addObject:[[CDType alloc] initBlockTypeWithTypes:nil]];
	[types addObject:[[CDType alloc] initBlockTypeWithTypes:[types copy]]];
	CDType *blockType = [[CDType alloc] initBlockTypeWithTypes:types];
	NSString *blockSignatureString = [blockType blockSignatureString];
	STAssertEqualObjects(blockSignatureString, @"void (^)(void (^)(void))", nil);
}

- (void)testBOOLArgument;
{
	NSMutableArray *types = [NSMutableArray new];
	[types addObject:[[CDType alloc] initSimpleType:'v']];
	[types addObject:[[CDType alloc] initBlockTypeWithTypes:nil]];
	[types addObject:[[CDType alloc] initSimpleType:'c']];
	CDType *blockType = [[CDType alloc] initBlockTypeWithTypes:types];
	NSString *blockSignatureString = [blockType blockSignatureString];
	STAssertEqualObjects(blockSignatureString, @"void (^)(BOOL)", nil);
}

@end
