#import <Foundation/NSObject.h>
#import "CDStructRegistrationProtocol.h"

@class NSArray, NSMutableArray, NSMutableSet, NSMutableString, NSString;
@class CDClassDump2, CDOCSymtab;

@interface CDOCProtocol : NSObject
{
    CDOCSymtab *nonretainedSymtab;

    NSString *name;
    NSMutableArray *protocols;
    NSArray *classMethods;
    NSArray *instanceMethods;

    NSMutableSet *adoptedProtocolNames;
}

- (id)init;
- (void)dealloc;

- (CDOCSymtab *)symtab;
- (void)setSymtab:(CDOCSymtab *)newSymtab;

- (CDClassDump2 *)classDumper;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (NSArray *)protocols;
- (void)addProtocol:(CDOCProtocol *)aProtocol;
- (void)removeProtocol:(CDOCProtocol *)aProtocol;
- (void)addProtocolsFromArray:(NSArray *)newProtocols;

- (NSArray *)classMethods;
- (void)setClassMethods:(NSArray *)newClassMethods;

- (NSArray *)instanceMethods;
- (void)setInstanceMethods:(NSArray *)newInstanceMethods;

- (NSString *)description;
- (void)appendToString:(NSMutableString *)resultString;
- (void)registerStructsWithObject:(id <CDStructRegistration>)anObject;

- (NSString *)sortableName;
- (NSComparisonResult)ascendingCompareByName:(CDOCProtocol *)otherProtocol;

@end
