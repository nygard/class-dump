#import "NSArray-Extensions.h"

#import <Foundation/Foundation.h>

@implementation NSArray (CDExtensions)

- (NSArray *)reversedArray;
{
    return [[self reverseObjectEnumerator] allObjects];
}

- (NSArray *)arrayByMappingSelector:(SEL)aSelector;
{
    NSMutableArray *newArray;
    int count, index;

    newArray = [NSMutableArray array];
    count = [self count];
    for (index = 0; index < count; index++)
        [newArray addObject:[[self objectAtIndex:index] performSelector:aSelector]];

    return newArray;
}

@end
