// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDOCClassReference.h"
#import "CDOCClass.h"
#import "CDSymbol.h"

@implementation CDOCClassReference

- (instancetype)initWithClassSymbol:(CDSymbol *)symbol;
{
    if ((self = [super init])) {
        _classSymbol = symbol;
    }

    return self;
}

- (instancetype)initWithClassObject:(CDOCClass *)classObject;
{
    if ((self = [super init])) {
        _classObject = classObject;
    }

    return self;
}

- (instancetype)initWithClassName:(NSString *)className;
{
    if ((self = [super init])) {
        _className = [className copy];
    }

    return self;
}

- (NSString *)className;
{
    if (_className != nil)
        return _className;
    else if (_classObject != nil)
        return [_classObject name];
    else if (_classSymbol != nil)
        return [CDSymbol classNameFromSymbolName:[_classSymbol name]];
    else
        return nil;
}

- (BOOL)isExternalClass;
{
    return (!_classObject && (!_classSymbol || [_classSymbol isExternal]));
}

@end
