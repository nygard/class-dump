#import "CDOCClass.h"

#import <Foundation/Foundation.h>

@implementation CDOCClass

- (id)init;
{
    if ([super init] == nil)
        return nil;

    return self;
}

- (void)dealloc;
{
    [name release];
    [superClassName release];
    [ivars release];
    [classMethods release];
    [instanceMethods release];

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

- (NSString *)superClassName;
{
    return superClassName;
}

- (void)setSuperClassName:(NSString *)newSuperClassName;
{
    if (newSuperClassName == superClassName)
        return;

    [superClassName release];
    superClassName = [newSuperClassName retain];
}

- (NSArray *)ivars;
{
    return ivars;
}

- (void)setIvars:(NSArray *)newIvars;
{
    if (newIvars == ivars)
        return;

    [ivars release];
    ivars = [newIvars retain];
}

- (NSArray *)classMethods;
{
    return classMethods;
}

- (void)setClassMethods:(NSArray *)newClassMethods;
{
    if (newClassMethods == classMethods)
        return;

    [classMethods release];
    classMethods = [newClassMethods retain];
}

- (NSArray *)instanceMethods;
{
    return instanceMethods;
}

- (void)setInstanceMethods:(NSArray *)newInstanceMethods;
{
    if (newInstanceMethods == instanceMethods)
        return;

    [instanceMethods release];
    instanceMethods = [newInstanceMethods retain];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, superClassName: %@", NSStringFromClass([self class]), name, superClassName];
}

@end
