#import "CDOCSymtab.h"

#import <Foundation/Foundation.h>

@implementation CDOCSymtab

- (id)init;
{
    if ([super init] == nil)
        return nil;

    return self;
}

- (void)dealloc;
{
    [classes release];
    [categories release];

    [super dealloc];
}

- (NSArray *)classes;
{
    return classes;
}

- (void)setClasses:(NSArray *)newClasses;
{
    if (newClasses == classes)
        return;

    [classes release];
    classes = [newClasses retain];
}

- (NSArray *)categories;
{
    return categories;
}

- (void)setCategories:(NSArray *)newCategories;
{
    if (newCategories == categories)
        return;

    [categories release];
    categories = [newCategories retain];
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
}

@end
