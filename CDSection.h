#import <Foundation/NSObject.h>
#include <mach-o/loader.h>

@class NSString;
@class CDMachOFile, CDSegmentCommand;

@interface CDSection : NSObject
{
    CDSegmentCommand *nonretainedSegment;

    const struct section *section;
    NSString *segmentName;
    NSString *sectionName;
}

- (id)initWithPointer:(const void *)ptr segment:(CDSegmentCommand *)aSegment;
- (void)dealloc;

- (CDSegmentCommand *)segment;
- (CDMachOFile *)machOFile;

- (NSString *)segmentName;
- (NSString *)sectionName;
- (unsigned long)addr;
- (unsigned long)size;
- (unsigned long)offset;

- (const void *)dataPointer; // Has no access to the mach-o file

- (NSString *)description;

- (BOOL)containsAddress:(unsigned long)vmaddr;
- (unsigned long)segmentOffsetForVMAddr:(unsigned long)vmaddr;

@end
