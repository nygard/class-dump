#import <Foundation/NSObject.h>

@interface CDOCModule : NSObject
{
    unsigned long version;
    //unsigned long size; // Not really relevant here
    NSString *name;
    unsigned long symtab;
}

- (id)init;
- (void)dealloc;

- (unsigned long)version;
- (void)setVersion:(unsigned long)aVersion;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (unsigned long)symtab;
- (void)setSymtab:(unsigned long)newSymtab;

@end
