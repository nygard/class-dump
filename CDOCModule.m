#import "CDOCModule.h"

#import <Foundation/Foundation.h>
#import "CDObjCSegmentProcessor.h"
#import "CDOCSymtab.h"

@implementation CDOCModule

- (id)initWithSegmentProcessor:(CDObjCSegmentProcessor *)aSegmentProcessor;
{
    if ([super init] == nil)
        return nil;

    nonretainedSegmentProcessor = aSegmentProcessor;
    version = 0;
    name = nil;
    symtab = nil;

    return self;
}

- (void)dealloc;
{
    [name release];
    [symtab release];
    nonretainedSegmentProcessor = nil;

    [super dealloc];
}

- (CDObjCSegmentProcessor *)segmentProcessor;
{
    return nonretainedSegmentProcessor;
}

- (CDClassDump2 *)classDumper;
{
    return [[self segmentProcessor] classDumper];
}

- (unsigned long)version;
{
    return version;
}

- (void)setVersion:(unsigned long)aVersion;
{
    version = aVersion;
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

- (CDOCSymtab *)symtab;
{
    return symtab;
}

- (void)setSymtab:(CDOCSymtab *)newSymtab;
{
    if (newSymtab == symtab)
        return;

    [symtab setModule:nil];
    [symtab release];
    symtab = [newSymtab retain];
    [symtab setModule:self];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, version: %d, symtab: %@", NSStringFromClass([self class]), name, version, symtab];
}

- (NSString *)formattedString;
{
    return [NSString stringWithFormat:@"/*\n * %@\n */\n", name];
}

- (void)appendToString:(NSMutableString *)resultString;
{
    [resultString appendFormat:@"/*\n * %@\n */\n\n", name];
    [symtab appendToString:resultString];
}

@end
