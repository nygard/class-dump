#import "CDOCIvar.h"

#import <Foundation/Foundation.h>
#import "CDClassDump.h"
#import "CDOCClass.h"
#import "CDTypeFormatter.h"

@implementation CDOCIvar

- (id)initWithName:(NSString *)aName type:(NSString *)aType offset:(int)anOffset;
{
    if ([super init] == nil)
        return nil;

    name = [aName retain];
    type = [aType retain];
    offset = anOffset;

    return self;
}

- (void)dealloc;
{
    [name release];
    [type release];

    [super dealloc];
}

- (CDOCClass *)OCClass;
{
    return nonretainedClass;
}

- (void)setOCClass:(CDOCClass *)newOCClass;
{
    nonretainedClass = newOCClass;
}

- (CDClassDump2 *)classDumper;
{
    return [[self OCClass] classDumper];
}

- (NSString *)name;
{
    return name;
}

- (NSString *)type;
{
    return type;
}

- (int)offset;
{
    return offset;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, type: '%@', offset: %d",
                     NSStringFromClass([self class]), name, type, offset];
}

- (NSString *)formattedString;
{
    return [NSString stringWithFormat:@"\t%@", name];
}

- (void)appendToString:(NSMutableString *)resultString;
{
    NSString *formattedString;

    //formattedString = [[CDTypeFormatter sharedIvarTypeFormatter] formatVariable:name type:type];
    formattedString = [[[self classDumper] ivarTypeFormatter] formatVariable:name type:type];
    if (formattedString != nil) {
        [resultString appendString:formattedString];
        [resultString appendString:@";"];
    } else
        [resultString appendFormat:@"    // Error parsing type: %@, name: %@", type, name];
}

@end
