#import <Foundation/NSObject.h>

@class NSData;
@class CDSegmentCommand;

#if 0
@interface CDFatMachOFile : NSObject
{
}

@end
#endif

@class NSArray;

@interface CDMachOFile : NSObject
{
    NSData *data;
    const struct mach_header *header;
    NSArray *loadCommands;
}

- (id)initWithFilename:(NSString *)filename;
- (void)dealloc;

- (NSArray *)_processLoadCommands;

- (NSArray *)loadCommands;
- (unsigned long)filetype;
- (unsigned long)flags;

- (NSString *)flagDescription;
- (NSString *)description;

- (CDSegmentCommand *)segmentWithName:(NSString *)segmentName;
- (CDSegmentCommand *)segmentContainingAddress:(unsigned long)vmaddr;
- (const void *)pointerFromVMAddr:(unsigned long)vmaddr;
- (const void *)pointerFromVMAddr:(unsigned long)vmaddr segmentName:(NSString *)aSegmentName;
- (NSString *)stringFromVMAddr:(unsigned long)vmaddr;

- (const void *)bytes;

@end
