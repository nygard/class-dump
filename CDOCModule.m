#import "CDOCModule.h"

#import <Foundation/Foundation.h>

@implementation CDOCModule

- (id)init;
{
    if ([super init] == nil)
        return nil;

    version = 0;
    name = nil;
    symtab = 0;

    return self;
}

- (void)dealloc;
{
    [name release];
    [super dealloc];
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

- (unsigned long)symtab;
{
    return symtab;
}

- (void)setSymtab:(unsigned long)newSymtab;
{
    symtab = newSymtab;
}

@end
