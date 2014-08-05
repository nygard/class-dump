#import "CDPbxProjectTarget.h"


@interface CDPbxProjectTarget ()
@property(nonatomic, readwrite) NSString *targetName;
@property(nonatomic, readwrite) NSString *headerName;
@property(nonatomic, readwrite) NSString *configFile;
@end

@implementation CDPbxProjectTarget {

}
- (instancetype)initWithTargetName:(NSString *)targetName precompiledHeaderName:(NSString *)precompiledHeader configurationFile:(NSString *)configurationFile {
    self = [self init];
    if (self) {
        self.targetName = targetName;
        self.headerName = precompiledHeader;
        self.configFile = configurationFile;
    }
    return self;
}

- (BOOL)isEqual:(id)other {
    if ([other isKindOfClass:[self class]]) {
        CDPbxProjectTarget *otherTarget = other;
        if ([otherTarget.targetName ?: @"" isEqualToString:self.targetName ?: @""] &&
                [otherTarget.headerName ?: @"" isEqualToString:self.headerName ?: @""] &&
                [otherTarget.configFile ?: @"" isEqualToString:self.configFile ?: @""]) {
            return YES;
        } else {
            return NO;
        }
    }
    return [super isEqual:other];
}

- (NSUInteger)hash {
    NSString *string = [NSString stringWithFormat:@"%@_%@_%@", self.targetName, self.configFile, self.headerName];
    return [string hash]; //Must be a unique unsigned integer
}

- (NSString *)debugDescription {

    return [NSString stringWithFormat:@"<CDPbxProjectTarget target=%@ header=%@ config=%@>", self.targetName, self.headerName, self.configFile];
}


@end
