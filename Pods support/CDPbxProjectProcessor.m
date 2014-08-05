#import "CDPbxProjectProcessor.h"
#import "CDPbxProjectParser.h"
#import "CDPbxProjectTarget.h"
#import "CDPodsFileProcessor.h"

@interface CDPbxProjectProcessor ()
@property(nonatomic, strong) NSPipe *outputPipe;
@end

@implementation CDPbxProjectProcessor {

}

- (void)processPodsProjectAtPath:(NSString *)podsPath symbolsFilePath:(NSString *)symbolsPath {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/plutil";
    task.arguments = @[@"-convert", @"json", podsPath, @"-o", @"-"];

    self.outputPipe = [[NSPipe alloc] init];
    task.standardOutput = self.outputPipe;
    [[self.outputPipe fileHandleForReading] readToEndOfFileInBackgroundAndNotify];

    [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleReadToEndOfFileCompletionNotification object:[self.outputPipe fileHandleForReading] queue:nil usingBlock:^(NSNotification *notification){
        NSData *output = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
        NSDictionary *projectJSON = [NSJSONSerialization JSONObjectWithData:output options:0 error:nil];
        CDPbxProjectParser *parser = [[CDPbxProjectParser alloc] initWithJsonDictionary:projectJSON];
        NSSet *targets = [parser findTargets];
        CDPodsFileProcessor *processor = [[CDPodsFileProcessor alloc] init];
        for (CDPbxProjectTarget *target in targets) {
            [processor processTarget:target symbolsFilePath:symbolsPath];
        }
    }];
    
    [task launch];

    [task waitUntilExit];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
