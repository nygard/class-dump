#import "CDOCClass.h"

#import <Foundation/Foundation.h>
#import "CDOCMethod.h"
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
    [protocols release];
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

- (NSArray *)protocols;
{
    return protocols;
}

- (void)setProtocols:(NSArray *)newProtocols;
{
    if (newProtocols == protocols)
        return;

    [protocols release];
    protocols = [newProtocols retain];
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
    if ([ivars count] > 0) {
        [result appendString:[[ivars arrayByMappingSelector:@selector(formattedString)] componentsJoinedByString:@"\n"]];
        [result appendString:@"\n"];
    }

    [result appendString:@"}\n\n"];
    if ([instanceMethods count] > 0) {
        [result appendString:[[instanceMethods arrayByMappingSelector:@selector(formattedString)] componentsJoinedByString:@"\n"]];
        [result appendString:@"\n\n"];
    }
    [result appendString:@"@end\n"];

    return result;
}

- (void)appendToString:(NSMutableString *)resultString;
{
    NSArray *sortedMethods;
    int count, index;

    [resultString appendFormat:@"@interface %@", name];
    if (superClassName != nil)
        [resultString appendFormat:@":%@", superClassName]; // Add space later, keep this way for backwards compatability

    // TODO: Need to handle adopted protocols
    if ([protocols count] > 0)
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];

    [resultString appendString:@"\n{\n"];
    count = [ivars count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            [[ivars objectAtIndex:index] appendToString:resultString];
            [resultString appendString:@"\n"];
        }
    }

    [resultString appendString:@"}\n\n"];

    sortedMethods = [classMethods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    count = [sortedMethods count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            [resultString appendString:@"+ "];
            [[sortedMethods objectAtIndex:index] appendToString:resultString];
            [resultString appendString:@"\n"];
        }
    }

    sortedMethods = [instanceMethods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    count = [sortedMethods count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            [resultString appendString:@"- "];
            [[sortedMethods objectAtIndex:index] appendToString:resultString];
            [resultString appendString:@"\n"];
        }
    }

    //[resultString appendFormat:@"// cm: %d, im: %d\n", [classMethods count], [instanceMethods count]];
    if ([classMethods count] > 0 || [instanceMethods count] > 0)
        [resultString appendString:@"\n"];
    [resultString appendString:@"@end\n\n"];
}

- (void)appendRawMethodsToString:(NSMutableString *)resultString;
{
    NSArray *sortedMethods;
    int count, index;

    [resultString appendFormat:@"\tClass %@\n", name];
    sortedMethods = [classMethods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    count = [sortedMethods count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            CDOCMethod *aMethod;

            aMethod = [sortedMethods objectAtIndex:index];
            [resultString appendFormat:@"%@\t%@\n", [aMethod name], [aMethod type]];
        }
    }

    sortedMethods = [instanceMethods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    count = [sortedMethods count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            CDOCMethod *aMethod;

            aMethod = [sortedMethods objectAtIndex:index];
            [resultString appendFormat:@"%@\t%@\n", [aMethod name], [aMethod type]];
        }
    }
}

- (NSComparisonResult)ascendingCompareByName:(CDOCClass *)otherClass;
{
    return [name compare:[otherClass name]];
}

@end
