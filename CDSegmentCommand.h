#import "CDLoadCommand.h"
#include <mach-o/loader.h>

@class NSArray;
@class CDSection;

@interface CDSegmentCommand : CDLoadCommand
{
    const struct segment_command *segmentCommand;

    NSString *name;
    NSArray *sections;
    //id contents;
}

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (void)_processSections;

- (NSString *)name;
- (unsigned long)vmaddr;
- (unsigned long)fileoff;
- (unsigned long)flags;
- (NSArray *)sections;

- (NSString *)flagDescription;
- (NSString *)extraDescription;

- (BOOL)containsAddress:(unsigned long)vmaddr;
- (unsigned long)segmentOffsetForVMAddr:(unsigned long)vmaddr;

- (CDSection *)sectionWithName:(NSString *)aName;

@end
