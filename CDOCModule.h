#import <Foundation/NSObject.h>

@class NSMutableString;
@class CDOCSymtab;

@interface CDOCModule : NSObject
{
    unsigned long version;
    //unsigned long size; // Not really relevant here
    NSString *name;
    CDOCSymtab *symtab;
}

- (id)init;
- (void)dealloc;

- (unsigned long)version;
- (void)setVersion:(unsigned long)aVersion;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (CDOCSymtab *)symtab;
- (void)setSymtab:(CDOCSymtab *)newSymtab;

- (NSString *)description;
- (NSString *)formattedString;

- (void)appendToString:(NSMutableString *)resultString;

@end
