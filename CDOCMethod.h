#import <Foundation/NSObject.h>

@class NSString;

@interface CDOCMethod : NSObject
{
    NSString *name;
    NSString *type;
    unsigned long imp;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType imp:(unsigned long)anImp;
- (void)dealloc;

- (NSString *)name;
- (NSString *)type;
- (unsigned long)imp;

- (NSString *)description;
- (NSString *)formattedString;

@end
