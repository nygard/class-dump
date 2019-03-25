// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "CDVisitorPropertyState.h"

#import "CDOCProperty.h"

@interface CDVisitorPropertyState ()
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
            _propertiesByName[property.name] = property;
            _propertiesByAccessor[property.getter] = property;
            if (property.isReadOnly == NO || property.setter)
                _propertiesByAccessor[property.setter] = property;
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
    return _propertiesByAccessor[str];
}

- (BOOL)hasUsedProperty:(CDOCProperty *)property;
{
    return _propertiesByName[property.name] == nil;
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
