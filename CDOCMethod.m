#import "CDOCMethod.h"

#import <Foundation/Foundation.h>
#import "CDTypeFormatter.h"

@implementation CDOCMethod

// TODO (2003-12-07): Reject unused -init method

- (id)initWithName:(NSString *)aName type:(NSString *)aType imp:(unsigned long)anImp;
{
    if ([super init] == nil)
        return nil;

    name = [aName retain];
    type = [aType retain];
    imp = anImp;

    return self;
}

- (void)dealloc;
{
    [name release];
    [type release];

    [super dealloc];
}

- (NSString *)name;
{
    return name;
}

- (NSString *)type;
{
    return type;
}

- (unsigned long)imp;
{
    return imp;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, type: %@, imp: 0x%08x",

                     NSStringFromClass([self class]), name, type, imp];
}

- (NSString *)formattedString;
{
    return [NSString stringWithFormat:@"- %@", name];
}

- (void)appendToString:(NSMutableString *)resultString;
{
    NSString *formattedString;

    //[resultString appendFormat:@"%@", name];
    formattedString = [CDTypeFormatter formatMethodName:name type:type];
    //NSLog(@"%s, formattedString: '%@'", _cmd, formattedString);
    if (formattedString != nil) {
        [resultString appendString:formattedString];
        [resultString appendString:@";"];
    } else
        [resultString appendFormat:@"    // Error parsing type: %@, name: %@", type, name];
}

- (NSComparisonResult)ascendingCompareByName:(CDOCMethod *)otherMethod;
{
    return [name compare:[otherMethod name]];
}

@end
