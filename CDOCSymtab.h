#import <Foundation/NSObject.h>

@class NSArray, NSMutableString;
@class CDClassDump2, CDOCModule;

@interface CDOCSymtab : NSObject
{
    CDOCModule *nonretainedModule;

    NSArray *classes;
    NSArray *categories;
}

- (id)init;
- (void)dealloc;

- (CDOCModule *)module;
- (void)setModule:(CDOCModule *)newModule;

- (CDClassDump2 *)classDumper;

- (NSArray *)classes;
- (void)setClasses:(NSArray *)newClasses;

- (NSArray *)categories;
- (void)setCategories:(NSArray *)newCategories;

- (NSString *)description;

- (void)appendToString:(NSMutableString *)resultString;

@end
