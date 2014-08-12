#import "CDSystemProtocolsProcessor.h"


@implementation CDSystemProtocolsProcessor {
    NSString *_sdkPath;
}

- (id)initWithSdkPath:(NSString *)sdkPath {
    self = [super init];
    if (self) {
        _sdkPath = sdkPath;
    }

    return self;
}

- (NSArray *)systemProtocolsSymbolsToExclude {
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/find";
    task.currentDirectoryPath = [_sdkPath stringByAppendingString:@"/System/Library/Frameworks"];
    task.arguments = @[@".", @"-name", @"*.h", @"-exec",
                       @"sed", @"-n", @"-e", @"s/.*@protocol[ \\t]*\\([a-zA-Z_][a-zA-Z0-9_]*\\).*/\\1/p", @"{}", @"+"];
    task.environment = @{@"LANG": @"C",
                         @"LC_CTYPE": @"C",
                         @"LC_ALL": @"C"};
    task.standardOutput = pipe;
    [task launch];
    [task waitUntilExit];

    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    
    if (data.length) {
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return [output componentsSeparatedByString:@"\n"];
    }

    return nil;
}

@end
