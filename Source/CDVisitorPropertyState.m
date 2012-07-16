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
    NSMutableDictionary *_propertiesByAccessor; // NSString (accessor)       -> CDOCProperty
    NSMutableDictionary *_propertiesByName;     // NSString (property name)  -> CDOCProperty
}

- (id)initWithProperties:(NSArray *)properties;
{
    if ((self = [super init])) {
        _propertiesByAccessor = [[NSMutableDictionary alloc] init];
        _propertiesByName = [[NSMutableDictionary alloc] init];
        
        for (CDOCProperty *property in properties) {
            //NSLog(@"property: %@, getter: %@, setter: %@", [property name], [property getter], [property setter]);
            [_propertiesByName setObject:property forKey:property.name];
            [_propertiesByAccessor setObject:property forKey:property.getter];
            if (property.isReadOnly == NO)
                [_propertiesByAccessor setObject:property forKey:property.setter];
        }
    }

    return self;
}

#pragma mark - Debugging

- (void)log;
{
    NSLog(@"propertiesByAccessor: %@", _propertiesByAccessor);
    NSLog(@"propertiesByName: %@", _propertiesByName);
}

#pragma mark -

- (CDOCProperty *)propertyForAccessor:(NSString *)str;
{
    return [_propertiesByAccessor objectForKey:str];
}

- (BOOL)hasUsedProperty:(CDOCProperty *)property;
{
    return [_propertiesByName objectForKey:property.name] == nil;
}

- (void)useProperty:(CDOCProperty *)property;
{
    [_propertiesByName removeObjectForKey:property.name];
}

- (NSArray *)remainingProperties;
{
    return [[_propertiesByName allValues] sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
}

@end
