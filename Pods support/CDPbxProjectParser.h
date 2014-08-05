#import <Foundation/Foundation.h>


@interface CDPbxProjectParser : NSObject

- (instancetype)initWithJsonDictionary:(NSDictionary *)project;
- (NSSet *)findTargets;
@end
