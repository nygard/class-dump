#import <Foundation/Foundation.h>


@interface CDPbxProjectTarget : NSObject

@property(nonatomic, readonly) NSString *targetName;

@property(nonatomic, readonly) NSString *headerName;

@property(nonatomic, readonly) NSString *configFile;

- (instancetype)initWithTargetName:(NSString *)targetName precompiledHeaderName:(NSString *)precompiledHeader configurationFile:(NSString *)configurationFile;

@end
