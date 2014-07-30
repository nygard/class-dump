#import <Foundation/Foundation.h>


@interface CDXibStoryBoardProcessor : NSObject
@property(nonatomic, copy) NSString *xibBaseDirectory;

- (void)obfuscateFilesUsingSymbols:(NSDictionary *)symbols;
@end
