// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDVisitorPropertyState.h"

#import "CDOCProperty.h"

@interface CDVisitorPropertyState ()
- (void)log;
@end

#pragma mark -

@implementation CDVisitorPropertyState
{
    NSMutableDictionary *propertiesByAccessor; // NSString (accessor)       -> CDOCProperty
    NSMutableDictionary *propertiesByName;     // NSString (property name)  -> CDOCProperty
}

- (id)initWithProperties:(NSArray *)properties;
{
    if ((self = [super init])) {
        propertiesByAccessor = [[NSMutableDictionary alloc] init];
        propertiesByName = [[NSMutableDictionary alloc] init];
        
        for (CDOCProperty *property in properties) {
            //NSLog(@"property: %@, getter: %@, setter: %@", [property name], [property getter], [property setter]);
            [propertiesByName setObject:property forKey:property.name];
            [propertiesByAccessor setObject:property forKey:property.getter];
            if (property.isReadOnly == NO)
                [propertiesByAccessor setObject:property forKey:property.setter];
        }
    }

    return self;
}

#pragma mark - Debugging

- (void)log;
{
    NSLog(@"propertiesByAccessor: %@", propertiesByAccessor);
    NSLog(@"propertiesByName: %@", propertiesByName);
}

#pragma mark -

- (CDOCProperty *)propertyForAccessor:(NSString *)str;
{
    return [propertiesByAccessor objectForKey:str];
}

- (BOOL)hasUsedProperty:(CDOCProperty *)property;
{
    return [propertiesByName objectForKey:property.name] == nil;
}

- (void)useProperty:(CDOCProperty *)property;
{
    [propertiesByName removeObjectForKey:property.name];
}

- (NSArray *)remainingProperties;
{
    return [[propertiesByName allValues] sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
}

@end
