//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import "CDOCProperty.h"

// http://developer.apple.com/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html

@implementation CDOCProperty

- (id)initWithName:(NSString *)aName attributes:(NSString *)someAttributes;
{
    if ([super init] == nil)
        return nil;

    name = [aName retain];
    attributes = [someAttributes retain];

    return self;
}

- (void)dealloc;
{
    [name release];
    [attributes release];

    [super dealloc];
}

- (NSString *)name;
{
    return name;
}

- (NSString *)attributes;
{
    return attributes;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> name: %@, attributes: %@",
                     NSStringFromClass([self class]), self,
                     name, attributes];
}

- (NSComparisonResult)ascendingCompareByName:(CDOCProperty *)otherProperty;
{
    return [name compare:[otherProperty name]];
}

@end
