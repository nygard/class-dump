#import <Foundation/NSObject.h>

#include <mach-o/loader.h>

@class CDMachOFile;

@interface CDLoadCommand : NSObject
{
    CDMachOFile *nonretainedMachOFile;

    const struct load_command *loadCommand;
}

+ (id)loadCommandWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;

- (CDMachOFile *)machOFile;

- (const void *)bytes;
- (unsigned long)cmdsize;

- (NSString *)commandName;
- (NSString *)description;
- (NSString *)extraDescription;

@end
