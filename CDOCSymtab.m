#import "CDOCSymtab.h"

#import <Foundation/Foundation.h>
#import "CDOCModule.h"

@implementation CDOCSymtab

- (id)init;
{
    if ([super init] == nil)
        return nil;

    nonretainedModule = nil;
    classes = nil;
    categories = nil;

    return self;
}

- (void)dealloc;
{
    nonretainedModule = nil;
    [classes release];
    [categories release];

    [super dealloc];
}

- (CDOCModule *)module;
{
    return nonretainedModule;
}

- (void)setModule:(CDOCModule *)newModule;
{
    nonretainedModule = newModule;
}

- (CDClassDump2 *)classDumper;
{

    return [[self module] classDumper];
}

- (NSArray *)classes;
{
    return classes;
}

- (void)setClasses:(NSArray *)newClasses;
{
    if (newClasses == classes)
        return;

    [classes makeObjectsPerformSelector:@selector(setSymtab:) withObject:nil];
    [classes release];
    classes = [newClasses retain];
    [classes makeObjectsPerformSelector:@selector(setSymtab:) withObject:self];
}

- (NSArray *)categories;
{
    return categories;
}

- (void)setCategories:(NSArray *)newCategories;
{
    if (newCategories == categories)
        return;

    [categories makeObjectsPerformSelector:@selector(setSymtab:) withObject:nil];
    [categories release];
    categories = [newCategories retain];
    [categories makeObjectsPerformSelector:@selector(setSymtab:) withObject:self];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] classes: %@, categories: %@", NSStringFromClass([self class]), classes, categories];
}

- (void)appendToString:(NSMutableString *)resultString;
{
    int count, index;

    count = [classes count];
    for (index = 0; index < count; index++)
        [[classes objectAtIndex:index] appendToString:resultString];

    // TODO: And categories.

    count = [categories count];
    for (index = 0; index < count; index++)
        [[categories objectAtIndex:index] appendToString:resultString];
}

@end
