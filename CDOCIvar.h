#import <Foundation/NSObject.h>

@class NSMutableString, NSString;
@class CDClassDump2, CDOCClass;

@interface CDOCIvar : NSObject
{
    CDOCClass *nonretainedClass;

    NSString *name;
    NSString *type;
    int offset;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType offset:(int)anOffset;
- (void)dealloc;

- (CDOCClass *)OCClass;
- (void)setOCClass:(CDOCClass *)newOCClass;

- (CDClassDump2 *)classDumper;

- (NSString *)name;
- (NSString *)type;
- (int)offset;

- (NSString *)description;
- (NSString *)formattedString;
- (void)appendToString:(NSMutableString *)resultString;

@end
