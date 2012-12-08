// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDProtocolUniquer.h"

#import "CDOCProtocol.h"
#import "CDOCMethod.h"

@implementation CDProtocolUniquer
{
    NSMutableDictionary *_protocolsByAddress; // non-uniqued
    NSMutableDictionary *_uniqueProtocolsByName;
    NSMutableDictionary *_uniqueProtocolsByAddress;
}

- (id)init;
{
    if ((self = [super init])) {
        _protocolsByAddress       = [[NSMutableDictionary alloc] init];
        _uniqueProtocolsByName    = [[NSMutableDictionary alloc] init];
        _uniqueProtocolsByAddress = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

#pragma mark - Gather

- (CDOCProtocol *)protocolWithAddress:(uint64_t)address;
{
    NSNumber *key = [NSNumber numberWithUnsignedLongLong:address];
    return _protocolsByAddress[key];
}

- (void)setProtocol:(CDOCProtocol *)protocol withAddress:(uint64_t)address;
{
    NSNumber *key = [NSNumber numberWithUnsignedLongLong:address];
    _protocolsByAddress[key] = protocol;
}

#pragma mark - Process

- (void)createUniquedProtocols;
{
    [_uniqueProtocolsByName removeAllObjects];
    [_uniqueProtocolsByAddress removeAllObjects];

    // Now unique the protocols by name and store in protocolsByName
    
    for (NSNumber *key in [[_protocolsByAddress allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        CDOCProtocol *p1 = _protocolsByAddress[key];
        CDOCProtocol *p2 = _uniqueProtocolsByName[p1.name];
        if (p2 == nil) {
            p2 = [[CDOCProtocol alloc] init];
            [p2 setName:[p1 name]];
            _uniqueProtocolsByName[p2.name] = p2;
            // adopted protocols still not set, will want uniqued instances
        } else {
        }
        _uniqueProtocolsByAddress[key] = p2;
    }
    
    //NSLog(@"uniqued protocol names: %@", [[[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@", "]);
    
    // And finally fill in adopted protocols, instance and class methods.  And properties.
    for (NSNumber *key in [[_protocolsByAddress allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        CDOCProtocol *p1 = _protocolsByAddress[key];
        CDOCProtocol *uniqueProtocol = _uniqueProtocolsByName[p1.name];
        for (CDOCProtocol *p2 in [p1 protocols])
            [uniqueProtocol addProtocol:_uniqueProtocolsByName[p2.name]];
        
        if ([[uniqueProtocol classMethods] count] == 0) {
            for (CDOCMethod *method in [p1 classMethods])
                [uniqueProtocol addClassMethod:method];
        } else {
            NSParameterAssert([[p1 classMethods] count] == 0 || [[uniqueProtocol classMethods] count] == [[p1 classMethods] count]);
        }
        
        if ([[uniqueProtocol instanceMethods] count] == 0) {
            for (CDOCMethod *method in [p1 instanceMethods])
                [uniqueProtocol addInstanceMethod:method];
        } else {
            if (!([[p1 instanceMethods] count] == 0 || [[uniqueProtocol instanceMethods] count] == [[p1 instanceMethods] count])) {
                //NSLog(@"p1 name: %@, uniqueProtocol name: %@", [p1 name], [uniqueProtocol name]);
                //NSLog(@"p1 instanceMethods: %@", [p1 instanceMethods]);
                //NSLog(@"uniqueProtocol instanceMethods: %@", [uniqueProtocol instanceMethods]);
            }
            NSParameterAssert([[p1 instanceMethods] count] == 0 || [[uniqueProtocol instanceMethods] count] == [[p1 instanceMethods] count]);
        }
        
        if ([[uniqueProtocol optionalClassMethods] count] == 0) {
            for (CDOCMethod *method in [p1 optionalClassMethods])
                [uniqueProtocol addOptionalClassMethod:method];
        } else {
            NSParameterAssert([[p1 optionalClassMethods] count] == 0 || [[uniqueProtocol optionalClassMethods] count] == [[p1 optionalClassMethods] count]);
        }
        
        if ([[uniqueProtocol optionalInstanceMethods] count] == 0) {
            for (CDOCMethod *method in [p1 optionalInstanceMethods])
                [uniqueProtocol addOptionalInstanceMethod:method];
        } else {
            NSParameterAssert([[p1 optionalInstanceMethods] count] == 0 || [[uniqueProtocol optionalInstanceMethods] count] == [[p1 optionalInstanceMethods] count]);
        }
        
        if ([[uniqueProtocol properties] count] == 0) {
            for (CDOCProperty *property in [p1 properties])
                [uniqueProtocol addProperty:property];
        } else {
            NSParameterAssert([[p1 properties] count] == 0 || [[uniqueProtocol properties] count] == [[p1 properties] count]);
        }
    }
    
    //NSLog(@"protocolsByName: %@", protocolsByName);
}

#pragma mark - Results

// These are useful after the call to -createUniqueProtocols

//- (CDOCProtocol *)uniqueProtocolWithName:(NSString *)name;
//{
//    return _uniqueProtocolsByName[name];
//}

- (CDOCProtocol *)uniqueProtocolWithAddress:(NSNumber *)address;
{
    return _uniqueProtocolsByAddress[address];
}

- (NSArray *)uniqueProtocolsAtAddresses:(NSArray *)addresses;
{
    NSMutableArray *protocols = [NSMutableArray array];

    for (NSNumber *protocolAddress in addresses) {
        CDOCProtocol *uniqueProtocol = [self uniqueProtocolWithAddress:protocolAddress];
        if (uniqueProtocol != nil)
            [protocols addObject:uniqueProtocol];
    }

    return [protocols copy];
}

- (NSArray *)uniqueProtocolsSortedByName;
{
    return [[_uniqueProtocolsByName allValues] sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
}

@end
