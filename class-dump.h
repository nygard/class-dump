//
// $Id: class-dump.h,v 1.14 2004/01/16 21:54:38 nygard Exp $
//

//
//  This file is a part of class-dump v2, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
//
//  You may contact the author by:
//     e-mail:  class-dump at codethecode.com
//

#import <Foundation/NSObject.h>

//======================================================================

#if 0
#include <regex.h>
@interface CDClassDump : NSObject
{
    NSString *mainPath;

    NSMutableArray *mappedFiles;
    NSMutableDictionary *mappedFilesByInstallName;
    NSMutableArray *sections;

    // Used in handleObjectiveCProtocols:expandProtocols:, showSingleModule:
    NSMutableDictionary *protocols;

    struct {
        unsigned int shouldShowIvarOffsets:1;
        unsigned int shouldShowMethodAddresses:1;
        unsigned int shouldExpandProtocols:1;
        unsigned int shouldMatchRegex:1;
        unsigned int shouldSort:1;
        unsigned int shouldSortClasses:1;
        unsigned int shouldGenerateHeaders:1;

        // Not really used yet:
        unsigned int shouldSwapFat:1;
        unsigned int shouldSwapMachO:1;
    } flags;

    regex_t compiledRegex;
}

- (id)initWithPath:(NSString *)aPath;
- (void)dealloc;

- (BOOL)shouldShowIvarOffsets;
- (void)setShouldShowIvarOffsets:(BOOL)newFlag;

- (BOOL)shouldShowMethodAddresses;
- (void)setShouldShowMethodAddresses:(BOOL)newFlag;

- (BOOL)shouldExpandProtocols;
- (void)setShouldExpandProtocols:(BOOL)newFlag;

- (BOOL)shouldSort;
- (void)setShouldSort:(BOOL)newFlag;

- (BOOL)shouldSortClasses;
- (void)setShouldSortClasses:(BOOL)newFlag;

- (BOOL)shouldGenerateHeaders;
- (void)setShouldGenerateHeaders:(BOOL)newFlag;

- (BOOL)shouldMatchRegex;
- (void)setShouldMatchRegex:(BOOL)newFlag;

- (BOOL)setRegex:(char *)regexCString errorMessage:(NSString **)errorMessagePointer;
- (BOOL)regexMatchesCString:(const char *)str;

- (NSArray *)sections;
- (void)addSectionInfo:(CDSectionInfo *)aSectionInfo;





// Remnants with notes:
- (void)processDylibCommand:(void *)start ptr:(void *)ptr;
- (void)processFvmlibCommand:(void *)start ptr:(void *)ptr;
- (NSArray *)handleObjectiveCMethods:(struct my_objc_methods *)methods methodType:(char)ch;
- (void)showSingleModule:(CDSectionInfo *)moduleInfo;

- (int)methodFormattingFlags;

@end
#endif
