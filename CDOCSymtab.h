#import <Foundation/NSObject.h>

@class NSArray;

@interface CDOCSymtab : NSObject
{
    NSArray *classes;
    NSArray *categories;
}

- (id)init;
- (void)dealloc;

@end
