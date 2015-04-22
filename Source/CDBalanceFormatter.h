// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

@interface CDBalanceFormatter : NSObject

- (id)initWithString:(NSString *)str;

- (void)parse:(NSString *)open index:(NSUInteger)openIndex level:(NSUInteger)level;

- (NSString *)format;

@end
