//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDMachOFile.h"

#import <Foundation/Foundation.h>
#include <mach-o/loader.h>

#import "CDDylibCommand.h"
#import "CDLoadCommand.h"
#import "CDSegmentCommand.h"

@implementation CDMachOFile

- (id)initWithFilename:(NSString *)aFilename;
{
    if ([super init] == nil)
        return nil;

    filename = [aFilename retain];
    data = nil;
    header = NULL;
    loadCommands = nil;
    nonretainedDelegate = nil;

    return self;
}

- (void)dealloc;
{
    [filename release];
    [loadCommands release]; // These all reference data, so release them first...  Should they just retain data themselves?
    [data release];
    nonretainedDelegate = nil;

    [super dealloc];
}

- (NSString *)filename;
{
    return filename;
}

- (id)delegate;
{
    return nonretainedDelegate;
}

- (void)setDelegate:(id)newDelegate;
{
    nonretainedDelegate = newDelegate;
}

- (void)process;
{
    assert(data == nil);

    data = [[NSData alloc] initWithContentsOfMappedFile:filename];
    header = [data bytes];
    if (header->magic != MH_MAGIC) {
        if (header->magic == MH_CIGAM)
            NSLog(@"MH_CIGAM");
        else
            NSLog(@"Not a Mach-O file.");

        // TODO (2003-12-14): Perhaps raise an exception or something.
    }

    loadCommands = [[self _processLoadCommands] retain];
}

- (NSArray *)_processLoadCommands;
{
    NSMutableArray *cmds;
    int count, index;
    const void *ptr;

    cmds = [NSMutableArray array];

    ptr = header + 1;
    count = header->ncmds;
    for (index = 0; index < count; index++) {
        CDLoadCommand *loadCommand;

        loadCommand = [CDLoadCommand loadCommandWithPointer:ptr machOFile:self];
        [cmds addObject:loadCommand];
        if ([loadCommand isKindOfClass:[CDDylibCommand class]] == YES) {
            [nonretainedDelegate machOFile:self loadDylib:(CDDylibCommand *)loadCommand];
        }

        ptr += [loadCommand cmdsize];
    }

    return [NSArray arrayWithArray:cmds];;
}

- (NSArray *)loadCommands;
{
    return loadCommands;
}

- (unsigned long)filetype;
{
    return header->filetype;
}

- (unsigned long)flags;
{
    return header->flags;
}

- (NSString *)filetypeDescription;
{
    switch ([self filetype]) {
      case MH_OBJECT: return @"OBJECT";
      case MH_EXECUTE: return @"EXECUTE";
      case MH_FVMLIB: return @"FVMLIB";
      case MH_CORE: return @"CORE";
      case MH_PRELOAD: return @"PRELOAD";
      case MH_DYLIB: return @"DYLIB";
      case MH_DYLINKER: return @"DYLINKER";
      case MH_BUNDLE: return @"BUNDLE";
      case MH_DYLIB_STUB: return @"DYLIB_STUB";
      default:
          break;
    }

    return nil;
}

- (NSString *)flagDescription;
{
    NSMutableArray *setFlags;
    unsigned long flags;

    setFlags = [NSMutableArray array];
    flags = [self flags];
    if (flags & MH_NOUNDEFS)
        [setFlags addObject:@"NOUNDEFS"];
    if (flags & MH_INCRLINK)
        [setFlags addObject:@"INCRLINK"];
    if (flags & MH_DYLDLINK)
        [setFlags addObject:@"DYLDLINK"];
    if (flags & MH_BINDATLOAD)
        [setFlags addObject:@"BINDATLOAD"];
    if (flags & MH_PREBOUND)
        [setFlags addObject:@"PREBOUND"];
    if (flags & MH_SPLIT_SEGS)
        [setFlags addObject:@"SPLIT_SEGS"];
    if (flags & MH_LAZY_INIT)
        [setFlags addObject:@"LAZY_INIT"];
    if (flags & MH_TWOLEVEL)
        [setFlags addObject:@"TWOLEVEL"];
    if (flags & MH_FORCE_FLAT)
        [setFlags addObject:@"FORCE_FLAT"];
    if (flags & MH_NOMULTIDEFS)
        [setFlags addObject:@"NOMULTIDEFS"];
    if (flags & MH_NOFIXPREBINDING)
        [setFlags addObject:@"NOFIXPREBINDING"];

    return [setFlags componentsJoinedByString:@" "];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"magic: 0x%08x, cputype: %d, cpusubtype: %d, filetype: %d, ncmds: %d, sizeofcmds: %d, flags: 0x%x",
                     header->magic, header->cputype, header->cpusubtype, header->filetype, header->ncmds, header->sizeofcmds, header->flags];
}

- (CDDylibCommand *)dylibIdentifier;
{
    int count, index;

    count = [loadCommands count];
    for (index = 0; index < count; index++) {
        CDLoadCommand *loadCommand;

        loadCommand = [loadCommands objectAtIndex:index];
        if ([loadCommand cmd] == LC_ID_DYLIB)
            return (CDDylibCommand *)loadCommand;
    }

    return nil;
}

- (CDSegmentCommand *)segmentWithName:(NSString *)segmentName;
{
    int count, index;

    count = [loadCommands count];
    for (index = 0; index < count; index++) {
        id loadCommand;

        loadCommand = [loadCommands objectAtIndex:index];
        if ([loadCommand isKindOfClass:[CDSegmentCommand class]] == YES && [[loadCommand name] isEqual:segmentName] == YES) {
            return loadCommand;
        }
    }

    return nil;
}

- (CDSegmentCommand *)segmentContainingAddress:(unsigned long)vmaddr;
{
    int count, index;

    count = [loadCommands count];
    for (index = 0; index < count; index++) {
        id loadCommand;

        loadCommand = [loadCommands objectAtIndex:index];
        if ([loadCommand isKindOfClass:[CDSegmentCommand class]] == YES && [loadCommand containsAddress:vmaddr] == YES) {
            return loadCommand;
        }
    }

    return nil;
}

- (void)foo;
{
    NSLog(@"busted");
}

- (void)showWarning:(NSString *)aWarning;
{
    NSLog(@"Warning: %@", aWarning);
}

- (const void *)pointerFromVMAddr:(unsigned long)vmaddr;
{
    return [self pointerFromVMAddr:vmaddr segmentName:nil]; // Any segment is fine
}

- (const void *)pointerFromVMAddr:(unsigned long)vmaddr segmentName:(NSString *)aSegmentName;
{
    CDSegmentCommand *segment;
    const void *ptr;

    if (vmaddr == 0)
        return NULL;

    segment = [self segmentContainingAddress:vmaddr];
    if (segment == NULL) {
        [self foo];
        NSLog(@"pointerFromVMAddr:, vmaddr: %p, segment: %@", vmaddr, segment);
    }
    //NSLog(@"[segment name]: %@", [segment name]);
    if (aSegmentName != nil && [[segment name] isEqual:aSegmentName] == NO) {
        //[self showWarning:[NSString stringWithFormat:@"addr %p in segment %@, required segment is %@", vmaddr, [segment name], aSegmentName]];
        return NULL;
    }
#if 0
    NSLog(@"vmaddr: %p, [data bytes]: %p, [segment fileoff]: %d, [segment segmentOffsetForVMAddr:vmaddr]: %d",
          vmaddr, [data bytes], [segment fileoff], [segment segmentOffsetForVMAddr:vmaddr]);
#endif
    ptr = [data bytes] + (vmaddr - [segment vmaddr] + [segment fileoff]);
    //ptr = [data bytes] + [segment fileoff] + [segment segmentOffsetForVMAddr:vmaddr];
    return ptr;
}

- (NSString *)stringFromVMAddr:(unsigned long)vmaddr;
{
    const void *ptr;

    ptr = [self pointerFromVMAddr:vmaddr];
    if (ptr == NULL)
        return nil;

    return [[[NSString alloc] initWithBytes:ptr length:strlen(ptr) encoding:NSASCIIStringEncoding] autorelease];
}

- (const void *)bytes;
{
    return [data bytes];
}

- (NSString *)importBaseName;
{
    if ([self filetype] == MH_DYLIB) {
        NSString *str;

        str = [filename lastPathComponent];
        if ([str hasPrefix:@"lib"] == YES)
            str = [[[str substringFromIndex:3] componentsSeparatedByString:@"."] objectAtIndex:0];

        return str;
    }

    return nil;
}

@end
