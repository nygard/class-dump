#import "NSArray-Extensions.h"

#import <Foundation/Foundation.h>

@implementation NSArray (CDExtensions)

- (NSArray *)reversedArray;
{
    return [[self reverseObjectEnumerator] allObjects];
}

@end
