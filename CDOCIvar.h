#import <Foundation/NSObject.h>

@class NSMutableString, NSString;

@interface CDOCIvar : NSObject
{
    NSString *name;
    NSString *type;
    int offset;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType offset:(int)anOffset;
- (void)dealloc;

- (NSString *)name;
- (NSString *)type;
- (int)offset;

- (NSString *)description;
- (NSString *)formattedString;
- (void)appendToString:(NSMutableString *)resultString;

@end
