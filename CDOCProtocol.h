#import <Foundation/NSObject.h>

// TODO (2003-12-08): What about protocols that adopt other protocols?

@class NSArray, NSString;

@interface CDOCProtocol : NSObject
{
    NSString *name;
    NSArray *methods;
}

- (id)init;
- (void)dealloc;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (NSArray *)methods;
- (void)setMethods:(NSArray *)newMethods;

- (NSString *)description;

@end
