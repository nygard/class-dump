#import "CDLoadCommand.h"
#include <mach-o/loader.h>

@interface CDDylibCommand : CDLoadCommand
{
    const struct dylib_command *dylibCommand;
    NSString *name;
}

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (NSString *)name;
- (unsigned long)timestamp;
- (unsigned long)currentVersion;
- (unsigned long)compatibilityVersion;

//- (NSString *)extraDescription;

@end
