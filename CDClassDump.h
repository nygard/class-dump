#import <Foundation/NSObject.h>
#import "CDStructRegistrationProtocol.h"

@class NSMutableArray, NSMutableDictionary, NSMutableString, NSString;
@class CDDylibCommand, CDMachOFile;


@interface CDClassDump2 : NSObject <CDStructRegistration>
{
    //NSMutableArray *machOFiles;
    NSMutableDictionary *machOFilesByID;
    NSMutableArray *objCSegmentProcessors;
    BOOL shouldProcessRecursively;

    NSMutableDictionary *structCounts;
    NSMutableDictionary *structsByName;
    NSMutableDictionary *anonymousStructs;
    int anonymousStructCounter;
}

- (id)init;
- (void)dealloc;

- (BOOL)shouldProcessRecursively;
- (void)setShouldProcessRecursively:(BOOL)newFlag;

- (void)processFilename:(NSString *)aFilename;
- (void)doSomething;

- (CDMachOFile *)machOFileWithID:(NSString *)anID;

- (void)machOFile:(CDMachOFile *)aMachOFile loadDylib:(CDDylibCommand *)aDylibCommand;

- (void)appendHeaderToString:(NSMutableString *)resultString;
- (void)appendNamedStructsToString:(NSMutableString *)resultString;
- (void)appendTypedefsToString:(NSMutableString *)resultString;

- (void)registerStructName:(NSString *)aName type:(NSString *)typeString;
- (NSString *)typedefNameForStruct:(NSString *)structTypeString;

@end
