// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

@interface NSString (CDExtensions)

+ (NSString *)stringWithFileSystemRepresentation:(const char *)str;
+ (NSString *)spacesIndentedToLevel:(NSUInteger)level;
+ (NSString *)spacesIndentedToLevel:(NSUInteger)level spacesPerLevel:(NSUInteger)spacesPerLevel;
+ (NSString *)stringWithUnichar:(unichar)character;

- (BOOL)isFirstLetterUppercase;

- (void)print;

- (NSString *)executablePathForFilename;

- (NSString *)SHA1DigestString;

- (BOOL)hasUnderscoreCapitalPrefix;
- (NSString *)capitalizeFirstCharacter;

@end

@interface NSMutableString (CDExtensions)

- (void)appendSpacesIndentedToLevel:(NSUInteger)level;
- (void)appendSpacesIndentedToLevel:(NSUInteger)level spacesPerLevel:(NSUInteger)spacesPerLevel;

@end
