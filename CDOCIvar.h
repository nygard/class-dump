#import <Foundation/NSObject.h>

@class NSMutableString, NSString;
@class CDClassDump2;

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
- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump;

@end
