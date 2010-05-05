// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDVisitorPropertyState.h"

#import "CDOCProperty.h"

@implementation CDVisitorPropertyState

- (id)initWithProperties:(NSArray *)properties;
{
    if ([super init] == nil)
        return nil;

    propertiesByAccessor = [[NSMutableDictionary alloc] init];
    propertiesByName = [[NSMutableDictionary alloc] init];

    for (CDOCProperty *property in properties) {
        //NSLog(@"property: %@, getter: %@, setter: %@", [property name], [property getter], [property setter]);
        [propertiesByName setObject:property forKey:[property name]];
        [propertiesByAccessor setObject:property forKey:[property getter]];
        if ([property isReadOnly] == NO)
            [propertiesByAccessor setObject:property forKey:[property setter]];
    }

    return self;
}

- (void)dealloc;
{
    [propertiesByAccessor release];
    [propertiesByName release];

    [super dealloc];
}

- (CDOCProperty *)propertyForAccessor:(NSString *)str;
{
    return [propertiesByAccessor objectForKey:str];
}

- (BOOL)hasUsedProperty:(CDOCProperty *)property;
{
    return [propertiesByName objectForKey:[property name]] == nil;
}

- (void)useProperty:(CDOCProperty *)property;
{
    [propertiesByName removeObjectForKey:[property name]];
}

- (NSArray *)remainingProperties;
{
    return [[propertiesByName allValues] sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
}

- (void)log;
{
    NSLog(@"propertiesByAccessor: %@", propertiesByAccessor);
    NSLog(@"propertiesByName: %@", propertiesByName);
}

@end
