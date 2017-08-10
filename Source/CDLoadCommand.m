// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDLoadCommand.h"

#import "CDLCDyldInfo.h"
#import "CDLCDylib.h"
#import "CDLCDylinker.h"
#import "CDLCDynamicSymbolTable.h"
#import "CDLCEncryptionInfo.h"
#import "CDLCFunctionStarts.h"
#import "CDLCLinkeditData.h"
#import "CDLCPrebindChecksum.h"
#import "CDLCPreboundDylib.h"
#import "CDLCRoutines32.h"
#import "CDLCRoutines64.h"
#import "CDLCRunPath.h"
#import "CDLCSegment.h"
#import "CDLCSubClient.h"
#import "CDLCSubFramework.h"
#import "CDLCSubLibrary.h"
#import "CDLCSubUmbrella.h"
#import "CDLCSymbolTable.h"
#import "CDLCTwoLevelHints.h"
#import "CDLCUnixThread.h"
#import "CDLCUUID.h"
#import "CDLCUnknown.h"
#import "CDLCVersionMinimum.h"
#import "CDMachOFile.h"

#import "CDLCMain.h"
#import "CDLCDataInCode.h"
#import "CDLCSourceVersion.h"

@implementation CDLoadCommand
{
    __weak CDMachOFile *_machOFile;
    NSUInteger _commandOffset;
}

+ (id)loadCommandWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    Class targetClass = [CDLCUnknown class];

    uint32_t val = [cursor peekInt32];

    switch (val) {
        case LC_SEGMENT:               targetClass = [CDLCSegment class]; break;
        case LC_SEGMENT_64:            targetClass = [CDLCSegment class]; break;
        case LC_SYMTAB:                targetClass = [CDLCSymbolTable class]; break;
            //case LC_SYMSEG: // obsolete
            //case LC_THREAD: // not used?
        case LC_UNIXTHREAD:            targetClass = [CDLCUnixThread class]; break;
            //case LC_LOADFVMLIB: // not used?
            //case LC_IDFVMLIB: // not used?
            //case LC_IDENT: // not used?
            //case LC_FVMFILE: // not used?
            //case LC_PREPAGE: // not used
        case LC_DYSYMTAB:              targetClass = [CDLCDynamicSymbolTable class]; break;
        case LC_LOAD_DYLIB:            targetClass = [CDLCDylib class]; break;
        case LC_ID_DYLIB:              targetClass = [CDLCDylib class]; break;
        case LC_LOAD_DYLINKER:         targetClass = [CDLCDylinker class]; break;
        case LC_ID_DYLINKER:           targetClass = [CDLCDylinker class]; break;
        case LC_PREBOUND_DYLIB:        targetClass = [CDLCPreboundDylib class]; break;
        case LC_ROUTINES:              targetClass = [CDLCRoutines32 class]; break;
        case LC_SUB_FRAMEWORK:         targetClass = [CDLCSubFramework class]; break;
            //case LC_SUB_UMBRELLA:    targetClass = [CDLCSubUmbrella class]; break;
        case LC_SUB_CLIENT:            targetClass = [CDLCSubClient class]; break;
            //case LC_SUB_LIBRARY:     targetClass = [CDLCSubLibrary class]; break;
        case LC_TWOLEVEL_HINTS:        targetClass = [CDLCTwoLevelHints class]; break;
        case LC_PREBIND_CKSUM:         targetClass = [CDLCPrebindChecksum class]; break;
        case LC_LOAD_WEAK_DYLIB:       targetClass = [CDLCDylib class]; break;
        case LC_ROUTINES_64:           targetClass = [CDLCRoutines64 class]; break;
        case LC_UUID:                  targetClass = [CDLCUUID class]; break;
        case LC_RPATH:                 targetClass = [CDLCRunPath class]; break;
        case LC_CODE_SIGNATURE:        targetClass = [CDLCLinkeditData class]; break;
        case LC_SEGMENT_SPLIT_INFO:    targetClass = [CDLCLinkeditData class]; break;
        case LC_REEXPORT_DYLIB:        targetClass = [CDLCDylib class]; break;
        case LC_LAZY_LOAD_DYLIB:       targetClass = [CDLCDylib class]; break;
        case LC_ENCRYPTION_INFO:
        case LC_ENCRYPTION_INFO_64:    targetClass = [CDLCEncryptionInfo class]; break;
        case LC_DYLD_INFO:             targetClass = [CDLCDyldInfo class]; break;
        case LC_DYLD_INFO_ONLY:        targetClass = [CDLCDyldInfo class]; break;

        case LC_LOAD_UPWARD_DYLIB:     targetClass = [CDLCDylib class]; break;
        case LC_VERSION_MIN_MACOSX:    targetClass = [CDLCVersionMinimum class]; break;
        case LC_VERSION_MIN_IPHONEOS:  targetClass = [CDLCVersionMinimum class]; break;
        case LC_FUNCTION_STARTS:       targetClass = [CDLCFunctionStarts class]; break;
        case LC_DYLD_ENVIRONMENT:      targetClass = [CDLCDylinker class]; break;
        case LC_MAIN:                  targetClass = [CDLCMain class]; break;
        case LC_DATA_IN_CODE:          targetClass = [CDLCDataInCode class]; break;
        case LC_SOURCE_VERSION:        targetClass = [CDLCSourceVersion class]; break;
        case LC_DYLIB_CODE_SIGN_DRS:   targetClass = [CDLCLinkeditData class]; break; // Designated Requirements
            
        default:
            NSLog(@"Unknown load command: 0x%08x", val);
    };

    //NSLog(@"targetClass: %@", NSStringFromClass(targetClass));

    return [[targetClass alloc] initWithDataCursor:cursor];
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super init])) {
        _machOFile = [cursor machOFile];
        _commandOffset = [cursor offset];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> cmd: 0x%08x (%@), cmdsize: %d // %@",
            NSStringFromClass([self class]), self,
            self.cmd, self.commandName, self.cmdsize, [self extraDescription]];
}

- (NSString *)extraDescription;
{
    return @"";
}

#pragma mark -

- (uint32_t)cmd;
{
    // Implement in subclasses
    [NSException raise:NSGenericException format:@"Must implement method in subclasses."];
    return 0;
}

- (uint32_t)cmdsize;
{
    // Implement in subclasses
    [NSException raise:NSGenericException format:@"Must implement method in subclasses."];
    return 0;
}

- (BOOL)mustUnderstandToExecute;
{
    return (self.cmd & LC_REQ_DYLD) != 0;
}

- (NSString *)commandName;
{
    switch (self.cmd) {
        case LC_SEGMENT:               return @"LC_SEGMENT";
        case LC_SYMTAB:                return @"LC_SYMTAB";
        case LC_SYMSEG:                return @"LC_SYMSEG";
        case LC_THREAD:                return @"LC_THREAD";
        case LC_UNIXTHREAD:            return @"LC_UNIXTHREAD";
        case LC_LOADFVMLIB:            return @"LC_LOADFVMLIB";
        case LC_IDFVMLIB:              return @"LC_IDFVMLIB";
        case LC_IDENT:                 return @"LC_IDENT";
        case LC_FVMFILE:               return @"LC_FVMFILE";
        case LC_PREPAGE:               return @"LC_PREPAGE";
        case LC_DYSYMTAB:              return @"LC_DYSYMTAB";
        case LC_LOAD_DYLIB:            return @"LC_LOAD_DYLIB";
        case LC_ID_DYLIB:              return @"LC_ID_DYLIB";
        case LC_LOAD_DYLINKER:         return @"LC_LOAD_DYLINKER";
        case LC_ID_DYLINKER:           return @"LC_ID_DYLINKER";
        case LC_PREBOUND_DYLIB:        return @"LC_PREBOUND_DYLIB";
        case LC_ROUTINES:              return @"LC_ROUTINES";
        case LC_SUB_FRAMEWORK:         return @"LC_SUB_FRAMEWORK";
        case LC_SUB_UMBRELLA:          return @"LC_SUB_UMBRELLA";
        case LC_SUB_CLIENT:            return @"LC_SUB_CLIENT";
        case LC_SUB_LIBRARY:           return @"LC_SUB_LIBRARY";
        case LC_TWOLEVEL_HINTS:        return @"LC_TWOLEVEL_HINTS";
        case LC_PREBIND_CKSUM:         return @"LC_PREBIND_CKSUM";
            
        case LC_LOAD_WEAK_DYLIB:       return @"LC_LOAD_WEAK_DYLIB";
        case LC_SEGMENT_64:            return @"LC_SEGMENT_64";
        case LC_ROUTINES_64:           return @"LC_ROUTINES_64";
        case LC_UUID:                  return @"LC_UUID";
        case LC_RPATH:                 return @"LC_RPATH";
        case LC_CODE_SIGNATURE:        return @"LC_CODE_SIGNATURE";
        case LC_SEGMENT_SPLIT_INFO:    return @"LC_SEGMENT_SPLIT_INFO";
        case LC_REEXPORT_DYLIB:        return @"LC_REEXPORT_DYLIB";
        case LC_LAZY_LOAD_DYLIB:       return @"LC_LAZY_LOAD_DYLIB";
        case LC_ENCRYPTION_INFO:       return @"LC_ENCRYPTION_INFO";
        case LC_DYLD_INFO:             return @"LC_DYLD_INFO";
        case LC_DYLD_INFO_ONLY:        return @"LC_DYLD_INFO_ONLY";
        case LC_LOAD_UPWARD_DYLIB:     return @"LC_LOAD_UPWARD_DYLIB";
        case LC_VERSION_MIN_MACOSX:    return @"LC_VERSION_MIN_MACOSX";
        case LC_VERSION_MIN_IPHONEOS:  return @"LC_VERSION_MIN_IPHONEOS";
        case LC_FUNCTION_STARTS:       return @"LC_FUNCTION_STARTS";
        case LC_DYLD_ENVIRONMENT:      return @"LC_DYLD_ENVIRONMENT";
        default:
            break;
    }

    return [NSString stringWithFormat:@"0x%08x", [self cmd]];
}

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;
{
    [resultString appendFormat:@"     cmd %@", [self commandName]];
    if (self.mustUnderstandToExecute)
        [resultString appendFormat:@" (must understand to execute)"];
    [resultString appendFormat:@"\n"];
    [resultString appendFormat:@" cmdsize %u\n", [self cmdsize]];
}

- (void)machOFileDidReadLoadCommands:(CDMachOFile *)machOFile;
{
}

@end
