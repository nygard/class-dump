#import <Foundation/NSObject.h>

@class NSArray, NSMutableArray, NSMutableSet, NSString;

@interface CDOCProtocol : NSObject
{
    NSString *name;
    NSMutableArray *protocols;
    NSArray *methods;

    NSMutableSet *adoptedProtocolNames;
}

- (id)init;
- (void)dealloc;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (NSArray *)protocols;
- (void)addProtocol:(CDOCProtocol *)aProtocol;
- (void)removeProtocol:(CDOCProtocol *)aProtocol;
- (void)addProtocolsFromArray:(NSArray *)newProtocols;

- (NSArray *)methods;
- (void)setMethods:(NSArray *)newMethods;

- (NSString *)description;
- (NSString *)formattedString;

@end
