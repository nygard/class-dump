#import <Foundation/NSObject.h>
#import "CDStructRegistrationProtocol.h"

@class NSMutableArray, NSMutableDictionary, NSMutableString, NSString;
@class CDDylibCommand, CDMachOFile;
@class CDType, CDTypeFormatter;

@interface CDClassDump2 : NSObject <CDStructRegistration>
{
    //NSMutableArray *machOFiles;
    NSMutableDictionary *machOFilesByID;
    NSMutableArray *objCSegmentProcessors;
    BOOL shouldProcessRecursively;

    // Can you say "just hacking out code"?
    NSMutableDictionary *structCountsByType;
    NSMutableDictionary *structsByName;
    NSMutableDictionary *anonymousStructNames;
    NSMutableDictionary *anonymousStructsByType;
    NSMutableDictionary *anonymousRemapping;

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

- (void)registerStruct:(CDType *)structType name:(NSString *)aName;
- (NSString *)typeFormatter:(CDTypeFormatter *)aFormatter typedefNameForStruct:(NSString *)structTypeString;

@end
