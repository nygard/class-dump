// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDOCClass, CDSymbol;

/*!
 * CDOCClassReference acts as a proxy object to a class that may be external. It can thus be repesented
 * as one of: a \c CDOCClass object (for internal classes), a \c CDSymbol object (for external classes),
 * or an \c NSString of the class name (for ObjC1 compatibility). The class name can then be inferred from
 * any of these representations.
 */
@interface CDOCClassReference : NSObject

@property (strong) CDOCClass *classObject;
@property (strong) CDSymbol *classSymbol;
@property (nonatomic, copy) NSString *className; // inferred from classObject / classSymbol if not set directly
@property (nonatomic, readonly, getter = isExternalClass) BOOL externalClass;

- (instancetype)initWithClassObject:(CDOCClass *)classObject;
- (instancetype)initWithClassSymbol:(CDSymbol *)symbol;
- (instancetype)initWithClassName:(NSString *)className;

@end
