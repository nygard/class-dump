//
// $Id: MappedFile.m,v 1.16 2003/09/05 20:30:24 nygard Exp $
//

//
//  This file is a part of class-dump v2, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997, 1998, 1999, 2000  Steve Nygard
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

#import "MappedFile.h"
#import <Foundation/Foundation.h>

#include <stdio.h>
#include <libc.h>
#include <ctype.h>

static BOOL debugFlag = NO;

static NSArray *envDyldFrameworkPath = nil;
static NSArray *envDyldLibraryPath = nil;
static NSArray *envDyldFallbackFrameworkPath = nil;
static NSArray *envDyldFallbackLibraryPath = nil;
static NSMutableArray *firstSearchPath = nil;
static NSMutableArray *secondSearchPath = nil;
static NSMutableSet *wrapperExtensions = nil;

@implementation MappedFile

+ (void)initialize;
{
    static BOOL initialized = NO;
    NSDictionary *environment;
    NSString *home, *debugFrameworkPaths;

    if (initialized == YES)
        return;
    initialized = YES;

    environment = [[NSProcessInfo processInfo] environment];
    debugFrameworkPaths = [environment objectForKey:@"ClassDumpDebugFrameworkPaths"];
    if (debugFrameworkPaths != nil && [debugFrameworkPaths isEqual:@"YES"])
        debugFlag = YES;

    envDyldFrameworkPath = [[[environment objectForKey:@"DYLD_FRAMEWORK_PATH"] componentsSeparatedByString:@":"] retain];
    envDyldLibraryPath = [[[environment objectForKey:@"DYLD_LIBRARY_PATH"] componentsSeparatedByString:@":"] retain];
    envDyldFallbackFrameworkPath = [[[environment objectForKey:@"DYLD_FALLBACK_FRAMEWORK_PATH"] componentsSeparatedByString:@":"] retain];
    envDyldFallbackLibraryPath = [[[environment objectForKey:@"DYLD_FALLBACK_LIBRARY_PATH"] componentsSeparatedByString:@":"] retain];
    home = [environment objectForKey:@"HOME"];

    if (debugFlag == YES) {
        NSLog(@"envDyldFrameworkPath: %@", envDyldFrameworkPath);
        NSLog(@"envDyldLibraryPath: %@", envDyldLibraryPath);
        NSLog(@"envDyldFallbackFrameworkPath: %@", envDyldFallbackFrameworkPath);
    }

    if (envDyldFallbackFrameworkPath == nil) {
        envDyldFallbackFrameworkPath = [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%@/Library/Frameworks", home],
                                                 @"/Local/Library/Frameworks",
                                                 @"/Network/Library/Frameworks",
                                                 @"/System/Library/Frameworks",
                                                 nil];
    }

    if (debugFlag == YES) {
        NSLog(@"envDyldFallbackFrameworkPath: %@", envDyldFallbackFrameworkPath);
        NSLog(@"envDyldFallbackLibraryPath: %@", envDyldFallbackLibraryPath);
    }

    if (envDyldFallbackLibraryPath == nil) {
        envDyldFallbackLibraryPath = [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%@/lib", home],
                                               @"/usr/local/lib",
                                               @"/lib",
                                               @"/usr/lib",
                                               nil];
    }

    if (debugFlag == YES)
        NSLog(@"envDyldFallbackLibraryPath: %@", envDyldFallbackLibraryPath);

    firstSearchPath = [[NSMutableArray alloc] initWithArray:envDyldFrameworkPath];
    [firstSearchPath addObjectsFromArray:envDyldLibraryPath];

    secondSearchPath = [[NSMutableArray alloc] initWithArray:envDyldFallbackFrameworkPath];
    [secondSearchPath addObjectsFromArray:envDyldFallbackLibraryPath];

    // TODO (old): Try grabbing these from an environment variable.
    wrapperExtensions = [[NSMutableSet alloc] init];
    [wrapperExtensions addObject:@"app"];
    [wrapperExtensions addObject:@"framework"];
    [wrapperExtensions addObject:@"bundle"];
    [wrapperExtensions addObject:@"palette"];
    [wrapperExtensions addObject:@"plugin"];
}

+ (BOOL)debug;
{
    return debugFlag;
}

+ (void)setDebug:(BOOL)flag;
{
    debugFlag = flag;
}

// Will map filename into memory.  If filename is a directory with specific suffixes, treat the directory as a wrapper.

- (id)initWithFilename:(NSString *)aFilename;
{
    NSString *standardPath;

    if ([super init] == nil)
        return nil;

    standardPath = [aFilename stringByStandardizingPath];

    if ([MappedFile isWrapperAtPath:standardPath] == YES) {
        standardPath = [MappedFile pathToMainFileOfWrapper:standardPath];
    }

    if (debugFlag == YES) {
        NSLog(@"----------------------------------------------------------------------");
        NSLog(@"before: %@", standardPath);
    }

    filename = [MappedFile adjustedFrameworkPath:standardPath];

    if (debugFlag == YES)
        NSLog(@"after:  %@", filename);

    data = [[NSData alloc] initWithContentsOfMappedFile:aFilename];
    if (data == nil) {
        NSLog(@"Couldn't map file: %@", filename);
        return nil;
    }

    installName = [aFilename retain];
    filename = [standardPath retain];

    return self;
}

- (void)dealloc;
{
    [installName release];
    [filename release];
    [data release];

    [super dealloc];
}

- (NSString *)installName;
{
    return installName;
}

- (NSString *)filename;
{
    return filename;
}

- (const void *)data;
{
    return [data bytes];
}

// How does this handle something ending in "/"?

+ (BOOL)isWrapperAtPath:(NSString *)path;
{
    return [wrapperExtensions containsObject:[path pathExtension]];
}

+ (NSString *)pathToMainFileOfWrapper:(NSString *)wrapperPath;
{
    NSString *base, *extension, *mainFile;

    base = [wrapperPath lastPathComponent];
    extension = [base pathExtension];
    base = [base stringByDeletingPathExtension];

    if ([@"framework" isEqual:extension] == YES) {
        mainFile = [NSString stringWithFormat:@"%@/%@", wrapperPath, base];
    } else {
        // app, bundle, palette, plugin
        mainFile = [NSString stringWithFormat:@"%@/Contents/MacOS/%@", wrapperPath, base];
    }

    return mainFile;
}

// Allow user to specify wrapper instead of the actual Mach-O file.
+ (NSString *)adjustUserSuppliedPath:(NSString *)path;
{
    NSString *fullyResolvedPath, *basePath, *resolvedBasePath;

    if ([MappedFile isWrapperAtPath:path] == YES) {
        path = [MappedFile pathToMainFileOfWrapper:path];
    }

    fullyResolvedPath = [path stringByResolvingSymlinksInPath];
    basePath = [path stringByDeletingLastPathComponent];
    resolvedBasePath = [basePath stringByResolvingSymlinksInPath];
    //NSLog(@"fullyResolvedPath: %@", fullyResolvedPath);
    //NSLog(@"basePath:          %@", basePath);
    //NSLog(@"resolvedBasePath:  %@", resolvedBasePath);

    // I don't want to resolve all of the symlinks, just the ones starting from the wrapper.
    // If I have a symlink from my home directory to /System/Library/Frameworks/AppKit.framework, I want to see the
    // path to my home directory.
    // This is an easy way to cheat so that we don't have to deal with NSFileManager ourselves.
    return [basePath stringByAppendingString:[fullyResolvedPath substringFromIndex:[resolvedBasePath length]]];
}

// Deal with '@executable_path'.
+ (NSString *)adjustInstallName:(NSString *)installName;
{
    return nil;
}

+ (NSString *)adjustedFrameworkPath:(NSString *)path;
{
    NSArray *pathComponents;
    int count, l;
    NSString *tailString = nil, *frameworkName = nil, *version = nil;
    NSRange tailRange;
    NSString *adjustedPath;
    NSFileManager *fileManager;

    pathComponents = [path pathComponents];
    count = [pathComponents count];
    if (count - 1 >= 0)
        frameworkName = [pathComponents objectAtIndex:count - 1];

    if (count - 3 >= 0) {
        if ([[pathComponents objectAtIndex:count - 3] isEqual:@"Versions"] == YES)
            version = [pathComponents objectAtIndex:count - 2];
    }

    if (debugFlag == YES)
        NSLog(@"frameworkName: %@", frameworkName);

    if (frameworkName == nil)
        return path;

    if (debugFlag == YES)
        NSLog(@"version: %@", version);
    if (version == nil)
        tailString = [NSString stringWithFormat:@"%@.framework/%@", frameworkName, frameworkName];
    else
        tailString = [NSString stringWithFormat:@"%@.framework/Versions/%@/%@", frameworkName, version, frameworkName];

    if (debugFlag == YES)
        NSLog(@"tailString: %@", tailString);

    tailRange = [path rangeOfString:tailString options:NSBackwardsSearch];
    if (debugFlag == YES)
        NSLog(@"tailRange.length: %d", tailRange.length);
    if (tailRange.length == 0)
        return path;

    fileManager = [NSFileManager defaultManager];

    count = [firstSearchPath count];
    for (l = 0; l < count; l++) {
        adjustedPath = [NSString stringWithFormat:@"%@/%@", [firstSearchPath objectAtIndex:l], tailString];
        if (debugFlag == YES)
            NSLog(@"adjustedPath: %@", adjustedPath);
        if ([fileManager fileExistsAtPath:adjustedPath] == YES)
            return adjustedPath;
    }

    count = [secondSearchPath count];
    for (l = 0; l < count; l++) {
        adjustedPath = [NSString stringWithFormat:@"%@/%@", [secondSearchPath objectAtIndex:l], tailString];
        if (debugFlag == YES)
            NSLog(@"adjustedPath: %@", adjustedPath);
        if ([fileManager fileExistsAtPath:adjustedPath] == YES)
            return adjustedPath;
    }

    return path;
}

@end
