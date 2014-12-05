//
//  CDdSYMProcessor.h
//  ios-class-guard
//
//  Created by Tomasz Grynfelder on 22/01/15.
//  Copyright (c) 2015 Polidea Sp. z o.o. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface CDdSYMProcessor : NSObject
- (NSData *)processDwarfdump:(NSData *)dwarfdumpContent withSymbols:(NSDictionary *)symbols;
- (void)writeDwarfdump:(NSData *)dwarfdumpContent originalDwarfPath:(NSString *)originalDwarfPath inputDSYM:(NSString *)inputDSYM outputDSYM:(NSString *)outputDSYM;
- (NSArray *)extractDwarfPathsForDSYM:(NSString *)path;
@end
