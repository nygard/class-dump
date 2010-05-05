// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

@interface CDBalanceFormatter : NSObject
{
    NSScanner *scanner;
    NSCharacterSet *openCloseSet;

    NSMutableString *result;
}

- (id)initWithString:(NSString *)str;
- (void)dealloc;

- (void)parse:(NSString *)open index:(NSUInteger)openIndex level:(NSUInteger)level;

- (NSString *)format;

@end
