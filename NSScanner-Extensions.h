//
// $Id: NSScanner-Extensions.h,v 1.7 2004/01/29 22:37:33 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSScanner.h>

#import <Foundation/NSString.h> // for unichar

@interface NSScanner (CDExtensions)

+ (NSCharacterSet *)cdOtherCharacterSet;
+ (NSCharacterSet *)cdIdentifierStartCharacterSet;
+ (NSCharacterSet *)cdIdentifierCharacterSet;

- (NSString *)peekCharacter;
- (unichar)peekChar;
- (BOOL)scanCharacter:(unichar *)value;
- (BOOL)scanCharacterFromSet:(NSCharacterSet *)set intoString:(NSString **)value;
- (BOOL)my_scanCharactersFromSet:(NSCharacterSet *)set intoString:(NSString **)value;

- (BOOL)scanIdentifierIntoString:(NSString **)stringPointer;

@end
