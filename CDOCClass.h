#import "CDOCProtocol.h"

@interface CDOCClass : CDOCProtocol
{
    NSString *superClassName; // TODO (2003-12-17): Have CDClassDump2 keep track of the name and build the tree,  linking directly to an appropriate class
    NSArray *ivars;
}

- (void)dealloc;

- (NSString *)superClassName;
- (void)setSuperClassName:(NSString *)newSuperClassName;

- (NSArray *)ivars;
- (void)setIvars:(NSArray *)newIvars;

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump;
- (void)registerStructsWithObject:(id <CDStructRegistration>)anObject;

@end
