#import <Foundation/NSObject.h>

@class NSMutableString;
@class CDClassDump2, CDObjCSegmentProcessor, CDOCSymtab;

@interface CDOCModule : NSObject
{
    CDObjCSegmentProcessor *nonretainedSegmentProcessor;

    unsigned long version;
    //unsigned long size; // Not really relevant here
    NSString *name;
    CDOCSymtab *symtab;
}

- (id)initWithSegmentProcessor:(CDObjCSegmentProcessor *)aSegmentProcessor;
- (void)dealloc;

- (CDObjCSegmentProcessor *)segmentProcessor;

- (CDClassDump2 *)classDumper;

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
