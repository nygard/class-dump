#import <Foundation/NSObject.h>

@class NSArray, NSMutableString;

@interface CDOCSymtab : NSObject
{
    NSArray *classes;
    NSArray *categories;
}

- (id)init;
- (void)dealloc;

- (NSArray *)classes;
- (void)setClasses:(NSArray *)newClasses;

- (NSArray *)categories;
- (void)setCategories:(NSArray *)newCategories;

- (NSString *)description;

- (void)appendToString:(NSMutableString *)resultString;

@end
