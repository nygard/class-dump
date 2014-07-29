#import <Foundation/Foundation.h>

@class CDPbxProjectTarget;


@interface CDPodsFileProcessor : NSObject
- (void)processTarget:(CDPbxProjectTarget *)target symbolsFilePath:(NSString *)symbolsFilePath;
@end
