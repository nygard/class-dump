//
// $Id: CDStructRegistrationProtocol.h,v 1.5 2004/01/06 02:31:43 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

@class NSString;
@class CDType;

@protocol CDStructRegistration
- (void)registerStruct:(CDType *)structType name:(NSString *)aName;
@end
