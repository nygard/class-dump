#import <Foundation/NSObject.h>

@class NSArray, NSMutableString, NSString;

@interface CDOCClass : NSObject
{
    NSString *name;
    NSString *superClassName; // TODO (2003-12-17): Have CDClassDump2 keep track of the name and build the tree,  linking directly to an appropriate class
    NSArray *protocols;
    NSArray *ivars;
    NSArray *classMethods;
    NSArray *instanceMethods;
}

- (id)init;
- (void)dealloc;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (NSString *)superClassName;
- (void)setSuperClassName:(NSString *)newSuperClassName;

- (NSArray *)protocols;
- (void)setProtocols:(NSArray *)newProtocols;

- (NSArray *)ivars;
- (void)setIvars:(NSArray *)newIvars;

- (NSArray *)classMethods;
- (void)setClassMethods:(NSArray *)newClassMethods;

- (NSArray *)instanceMethods;
- (void)setInstanceMethods:(NSArray *)newInstanceMethods;

- (NSString *)description;

- (NSString *)formattedString;
- (void)appendToString:(NSMutableString *)resultString;
- (void)appendRawMethodsToString:(NSMutableString *)resultString;

- (NSComparisonResult)ascendingCompareByName:(CDOCClass *)otherIvar;

@end
