#import <Foundation/NSObject.h>

@class NSArray, NSString;

@interface CDOCClass : NSObject
{
    NSString *name;
    NSString *superClassName; // TODO (2003-12-17): Have CDClassDump2 keep track of the name and build the tree,  linking directly to an appropriate class
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

- (NSArray *)ivars;
- (void)setIvars:(NSArray *)newIvars;

- (NSArray *)classMethods;
- (void)setClassMethods:(NSArray *)newClassMethods;

- (NSArray *)instanceMethods;
- (void)setInstanceMethods:(NSArray *)newInstanceMethods;

- (NSString *)description;

- (NSString *)formattedString;

@end
