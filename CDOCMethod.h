#import <Foundation/NSObject.h>

@class NSMutableString, NSString;
@class CDClassDump2, CDOCProtocol;

@interface CDOCMethod : NSObject
{
    CDOCProtocol *nonretainedProtocol;

    NSString *name;
    NSString *type;
    unsigned long imp;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType imp:(unsigned long)anImp;
- (void)dealloc;

- (CDOCProtocol *)protocol;
- (void)setProtocol:(CDOCProtocol *)newProtocol;

- (CDClassDump2 *)classDumper;

- (NSString *)name;
- (NSString *)type;
- (unsigned long)imp;

- (NSString *)description;
- (NSString *)formattedString;
- (void)appendToString:(NSMutableString *)resultString;

- (NSComparisonResult)ascendingCompareByName:(CDOCMethod *)otherMethod;

@end
