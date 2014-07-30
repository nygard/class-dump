#import "CDXibStoryBoardProcessor.h"
#import "CDXibStoryboardParser.h"


@implementation CDXibStoryBoardProcessor {

}

- (void)obfuscateFilesUsingSymbols:(NSDictionary *)symbols {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    NSURL *directoryURL;
    if (self.xibBaseDirectory) {
        directoryURL = [NSURL URLWithString:self.xibBaseDirectory];
    } else {
        directoryURL = [NSURL URLWithString:@"."];
    }

    NSDirectoryEnumerator *enumerator = [fileManager
        enumeratorAtURL:directoryURL
        includingPropertiesForKeys:keys
        options:0
        errorHandler:^(NSURL *url, NSError *error) {
            // Handle the error.
            // Return YES if the enumeration should continue after the error.
            return YES;
    }];

    CDXibStoryboardParser *parser = [[CDXibStoryboardParser alloc] init];
    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error] && ![isDirectory boolValue]) {
            if ([url.absoluteString hasSuffix:@".xib"] || [url.absoluteString hasSuffix:@".storyboard"]) {
                NSLog(@"Obfuscating IB file at path %@", url);
                NSData *data = [parser obfuscatedXmlData:[NSData dataWithContentsOfURL:url] symbols:symbols];
                [data writeToURL:url atomically:YES];
            }
        }
    }
}
@end
