//
// $Id: CDStructRegistrationProtocol.h,v 1.6 2004/01/07 18:14:18 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

@class NSString;
@class CDType;

@protocol CDStructRegistration
- (void)registerStruct:(CDType *)structType name:(NSString *)aName countReferences:(BOOL)shouldCountReferences;
@end
