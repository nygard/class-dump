#import <Foundation/Foundation.h>


@interface CDPbxProjectProcessor : NSObject
- (void)processPodsProjectAtPath:(NSString *)podsPath symbolsFilePath:(NSString *)symbolsPath;
@end
