#import "CDOCProtocol.h"

#import <Foundation/Foundation.h>
#import "NSArray-Extensions.h"

@implementation CDOCProtocol

- (id)init;
{
    if ([super init] == nil)
        return nil;

    protocols = [[NSMutableArray alloc] init];
    adoptedProtocolNames = [[NSMutableSet alloc] init];

    return self;
}

- (void)dealloc;
{
    [name release];
    [protocols release];
    [methods release];
    [adoptedProtocolNames release];

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

// This assumes that the protocol name doesn't change after it's been added to this.
- (void)addProtocol:(CDOCProtocol *)aProtocol;
{
    if ([adoptedProtocolNames containsObject:[aProtocol name]] == NO) {
        [protocols addObject:aProtocol];
        [adoptedProtocolNames addObject:[aProtocol name]];
    }
}

- (void)removeProtocol:(CDOCProtocol *)aProtocol;
{
    [adoptedProtocolNames removeObject:[aProtocol name]];
    [protocols removeObject:aProtocol];
}

- (void)addProtocolsFromArray:(NSArray *)newProtocols;
{
    int count, index;

    count = [newProtocols count];
    for (index = 0; index < count; index++)
        [self addProtocol:[newProtocols objectAtIndex:index]];
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
    [result appendString:@"\n"];
    [result appendString:[[methods arrayByMappingSelector:@selector(formattedString)] componentsJoinedByString:@"\n"]];
    [result appendString:@"\n@end\n"];

    return result;
}

@end
