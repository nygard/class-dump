#import <Foundation/NSObject.h>

@class NSMutableString, NSString;

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
- (void)appendToString:(NSMutableString *)resultString;

- (NSComparisonResult)ascendingCompareByName:(CDOCMethod *)otherMethod;

@end
