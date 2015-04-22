// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

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
        CDOCProtocol *uniqueProtocol = _uniqueProtocolsByName[p1.name];
        if (uniqueProtocol == nil) {
            uniqueProtocol = [[CDOCProtocol alloc] init];
            [uniqueProtocol setName:[p1 name]];
            _uniqueProtocolsByName[uniqueProtocol.name] = uniqueProtocol;
            // adopted protocols still not set, will want uniqued instances
        } else {
        }
        _uniqueProtocolsByAddress[key] = uniqueProtocol;
    }
    
    //NSLog(@"uniqued protocol names: %@", [[[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@", "]);
    
    // And finally fill in adopted protocols, instance and class methods.  And properties.
    for (NSNumber *key in [[_protocolsByAddress allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        CDOCProtocol *p1 = _protocolsByAddress[key];
        CDOCProtocol *uniqueProtocol = _uniqueProtocolsByName[p1.name];
        
        // Add the uniqued adopted protocols
        for (CDOCProtocol *p2 in [p1 protocols])
            [uniqueProtocol addProtocol:_uniqueProtocolsByName[p2.name]];
        
        [uniqueProtocol mergeMethodsFromProtocol:p1];
        [uniqueProtocol mergePropertiesFromProtocol:p1];
    }
    
    //NSLog(@"protocolsByName: %@", protocolsByName);
}

#pragma mark - Results

// These are useful after the call to -createUniqueProtocols

- (NSArray *)uniqueProtocolsAtAddresses:(NSArray *)addresses;
{
    NSMutableArray *protocols = [NSMutableArray array];

    for (NSNumber *protocolAddress in addresses) {
        CDOCProtocol *uniqueProtocol = _uniqueProtocolsByAddress[protocolAddress];
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
