#import "CDOCProtocol.h"

#import <Foundation/Foundation.h>

@implementation CDOCProtocol

- (id)init;
{
    if ([super init] == nil)
        return nil;

    return self;
}

- (void)dealloc;
{
    [name release];
    [methods release];

    [super dealloc];
}

- (NSString *)name;
{
    return name;
}

- (void)setName:(NSString *)newName;
{
    if (newName == name)
        return;

    [name release];
    name = [newName retain];
}

- (NSArray *)methods;
{
    return methods;
}

- (void)setMethods:(NSArray *)newMethods;
{
    if (newMethods == methods)
        return;

    [methods release];
    methods = [newMethods retain];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, methods: %@",
                     NSStringFromClass([self class]), name, methods];
}

@end
