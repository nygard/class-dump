#import "CDOCClass.h"

#import <Foundation/Foundation.h>
#import "NSArray-Extensions.h"

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

- (NSString *)formattedString;
{
    NSMutableString *result;

    result = [NSMutableString string];
    [result appendFormat:@"@interface %@", name];
    if (superClassName != nil)
        [result appendFormat:@" : %@", superClassName];

    // Need to handle adopted protocols
    [result appendString:@"\n{\n"];
    if ([ivars count] > 0)
        [result appendString:[[ivars arrayByMappingSelector:@selector(formattedString)] componentsJoinedByString:@"\n"]];
    [result appendString:@"\n}\n\n"];
    if ([instanceMethods count] > 0) {
        [result appendString:[[instanceMethods arrayByMappingSelector:@selector(formattedString)] componentsJoinedByString:@"\n"]];
        [result appendString:@"\n\n"];
    }
    [result appendString:@"@end\n"];

    return result;
}

@end
