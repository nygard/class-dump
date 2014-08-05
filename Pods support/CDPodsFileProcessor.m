#import "CDPodsFileProcessor.h"
#import "CDPbxProjectTarget.h"


@implementation CDPodsFileProcessor {

}
- (void)processTarget:(CDPbxProjectTarget *)target symbolsFilePath:(NSString *)symbolsFilePath {
    if (target.headerName.length == 0 || target.configFile.length == 0) {
        NSLog(@"Error: Could not process target %@ config %@ header %@. Some values are missing.", target.targetName, target.configFile, target.headerName);
        return;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    NSURL *directoryURL = [[NSURL alloc] initWithString:@"."];

    NSDirectoryEnumerator *enumerator = [fileManager
        enumeratorAtURL:directoryURL
        includingPropertiesForKeys:keys
        options:0
        errorHandler:^(NSURL *url, NSError *error) {
            // Handle the error.
            // Return YES if the enumeration should continue after the error.
            return YES;
    }];


    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error] && ![isDirectory boolValue]) {
            NSString *symbolsFileName = [[symbolsFilePath pathComponents] lastObject];
            if ([[[url.absoluteString pathComponents] lastObject] isEqualToString:target.headerName]) {
                NSLog(@"Obfuscating precompiled header %@", target.headerName);
                NSString *headerData = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
                NSString *obfuscatedData = [NSString stringWithFormat:@"#import \"%@\"\n%@", symbolsFileName, headerData];
                [obfuscatedData writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
            if ([[[url.absoluteString pathComponents] lastObject] isEqualToString:target.configFile]) {
                NSLog(@"Adding symbols file path to configuration file %@", target.configFile);
                NSString *configData = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
                NSArray *pathComponents = [symbolsFilePath pathComponents];

                NSString *symbolsDirectory = @"";
                for (NSString *component in pathComponents) {
                    if (![component isEqualToString:symbolsFileName]) {
                        symbolsDirectory = [symbolsDirectory stringByAppendingPathComponent:component];
                    }
                }
                NSString *processedData = [configData stringByReplacingOccurrencesOfString:@"HEADER_SEARCH_PATHS = " withString:[NSString stringWithFormat:@"HEADER_SEARCH_PATHS = \"${PODS_ROOT}/../%@\" ", symbolsDirectory]];
                [processedData writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
        }
    }
}

@end
