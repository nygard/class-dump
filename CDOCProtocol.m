#import "CDOCProtocol.h"

#import <Foundation/Foundation.h>
#import "NSArray-Extensions.h"

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
    return [NSString stringWithFormat:@"[%@] name: %@, protocols: %@, methods: %@", NSStringFromClass([self class]), name, protocols, methods];
}

- (NSString *)formattedString;
{
    NSMutableString *result;

    result = [NSMutableString string];
    [result appendFormat:@"@protocol %@", name];
    if ([protocols count] > 0)
        [result appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];

    // TODO: And the methods
    [result appendString:@"\n@end\n"];

    return result;
}

@end
