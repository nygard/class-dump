#import "CDPbxProjectParser.h"
#import "CDPbxProjectTarget.h"


@interface CDPbxProjectParser ()
@property(nonatomic, strong) NSDictionary *project;
@end

@implementation CDPbxProjectParser {

}
- (instancetype)initWithJsonDictionary:(NSDictionary *)project {
    self = [self init];
    if (self) {
        self.project = project;
    }
    return self;
}

- (NSSet *)findTargets {
    __weak CDPbxProjectParser *weakSelf = self;
    NSMutableSet *targets = [NSMutableSet set];
    [self iterateBuildConfigurationsWithBlock:^(NSString *targetName, NSDictionary *buildConfiguration) {
        NSDictionary *buildSettings = buildConfiguration[@"buildSettings"];
        NSString *prefixHeaderName = buildSettings[@"GCC_PREFIX_HEADER"];

        NSDictionary *baseConfiguration = [weakSelf getObjectWithHash:buildConfiguration[@"baseConfigurationReference"]];
        NSString *configFileName = baseConfiguration[@"path"];

        [targets addObject:[[CDPbxProjectTarget alloc] initWithTargetName:targetName precompiledHeaderName:prefixHeaderName configurationFile:configFileName]];

    }];

    return targets;
}

#pragma mark - helpers

- (void)iterateBuildConfigurationsWithBlock:(void (^)(NSString *, NSDictionary *))iterationBlock {
    __weak CDPbxProjectParser *weakSelf = self;
    [self iterateTargetsWithBlock:^(NSDictionary *target) {
        NSDictionary *buildConfigurationList = [weakSelf getObjectWithHash:target[@"buildConfigurationList"]];
        NSArray *buildConfigurations = buildConfigurationList[@"buildConfigurations"];
        for (NSString *buildConfigurationHash in buildConfigurations) {
            NSDictionary *buildConfiguration = [weakSelf getObjectWithHash:buildConfigurationHash];
            if (iterationBlock) {
                iterationBlock(target[@"name"], buildConfiguration);
            } else {
                break;
            }
        }
    }];
}

- (void)iterateTargetsWithBlock:(void (^)(NSDictionary *))iterationBlock {
    NSString *rootObjectHash = self.project[@"rootObject"];
    NSDictionary *rootObject = [self getObjectWithHash:rootObjectHash];
    NSArray *targetsHashArray = rootObject[@"targets"];

    for (NSString *targetHash in targetsHashArray) {
        if (iterationBlock) {
            NSDictionary *target = [self getObjectWithHash:targetHash];
            iterationBlock(target);
        } else {
            break;
        }
    }
}

- (id)getObjectWithHash:(NSString *)hash {
    return self.project[@"objects"][hash];
}

@end
