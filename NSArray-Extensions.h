#import <Foundation/NSArray.h>

@interface NSArray (CDExtensions)

- (NSArray *)reversedArray;
- (NSArray *)arrayByMappingSelector:(SEL)aSelector;

@end
