//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2005  Steve Nygard

#import "CDOCSymtab.h"

#import <Foundation/Foundation.h>
#import "CDClassDump.h"
#import "CDOCCategory.h"
#import "CDOCClass.h"
#import "CDSymbolReferences.h"

@implementation CDOCSymtab

- (id)init;
{
    if ([super init] == nil)
        return nil;

    classes = nil;
    categories = nil;

    return self;
}

- (void)dealloc;
{
    [classes release];
    [categories release];

    [super dealloc];
}

- (NSArray *)classes;
{
    return classes;
}

- (void)setClasses:(NSArray *)newClasses;
{
    if (newClasses == classes)
        return;

    [classes release];
    classes = [newClasses retain];
}

- (NSArray *)categories;
{
    return categories;
}

- (void)setCategories:(NSArray *)newCategories;
{
    if (newCategories == categories)
        return;

    [categories release];
    categories = [newCategories retain];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] classes: %@, categories: %@", NSStringFromClass([self class]), classes, categories];
}

- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;
{
    int count, index;

    count = [classes count];
    for (index = 0; index < count; index++)
        [[classes objectAtIndex:index] registerStructuresWithObject:anObject phase:phase];

    count = [categories count];
    for (index = 0; index < count; index++)
        [[categories objectAtIndex:index] registerStructuresWithObject:anObject phase:phase];
}

- (void)registerClassesWithObject:(NSMutableDictionary *)aDictionary frameworkName:(NSString *)aFrameworkName;
{
    int count, index;

    count = [classes count];
    for (index = 0; index < count; index++) {
        [aDictionary setObject:aFrameworkName forKey:[[classes objectAtIndex:index] name]];
    }
}

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump;
{
    int count, index;

    count = [classes count];
    for (index = 0; index < count; index++)
        [[classes objectAtIndex:index] appendToString:resultString classDump:aClassDump symbolReferences:nil];

    count = [categories count];
    for (index = 0; index < count; index++)
        [[categories objectAtIndex:index] appendToString:resultString classDump:aClassDump symbolReferences:nil];
}

- (void)generateSeparateHeadersClassDump:(CDClassDump *)aClassDump;
{
    NSString *outputPath;
    int count, index;
    NSMutableString *resultString;
    outputPath = [aClassDump outputPath];

    count = [classes count];
    for (index = 0; index < count; index++) {
        CDOCClass *aClass;
        NSString *filename;
        CDSymbolReferences *symbolReferences;
        NSString *referenceString;
        unsigned int referenceIndex;

        aClass = [classes objectAtIndex:index];
        if ([aClassDump shouldMatchRegex] == YES && [aClassDump regexMatchesString:[aClass name]] == NO)
            continue;

        resultString = [[NSMutableString alloc] init];
        [aClassDump appendHeaderToString:resultString];

        symbolReferences = [[CDSymbolReferences alloc] init];

        [aClassDump appendImportForClassName:[aClass superClassName] toString:resultString];

        referenceIndex = [resultString length];
        [aClass appendToString:resultString classDump:aClassDump symbolReferences:symbolReferences];

        [symbolReferences removeClassName:[aClass name]];
        [symbolReferences removeClassName:[aClass superClassName]];
        referenceString = [symbolReferences referenceString];
        if (referenceString != nil)
            [resultString insertString:referenceString atIndex:referenceIndex];

        filename = [NSString stringWithFormat:@"%@.h", [aClass name]];
        if (outputPath != nil)
            filename = [outputPath stringByAppendingPathComponent:filename];

        [[resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];

        [symbolReferences release];
        [resultString release];
    }

    count = [categories count];
    for (index = 0; index < count; index++) {
        CDOCCategory *aCategory;
        NSString *filename;
        CDSymbolReferences *symbolReferences;
        NSString *referenceString;
        unsigned int referenceIndex;

        aCategory = [categories objectAtIndex:index];
        if ([aClassDump shouldMatchRegex] == YES && [aClassDump regexMatchesString:[aCategory sortableName]] == NO)
            continue;

        resultString = [[NSMutableString alloc] init];
        [aClassDump appendHeaderToString:resultString];

        symbolReferences = [[CDSymbolReferences alloc] init];

        [aClassDump appendImportForClassName:[aCategory className] toString:resultString];

        referenceIndex = [resultString length];
        [aCategory appendToString:resultString classDump:aClassDump symbolReferences:symbolReferences];

        [symbolReferences removeClassName:[aCategory className]];
        referenceString = [symbolReferences referenceString];
        if (referenceString != nil)
            [resultString insertString:referenceString atIndex:referenceIndex];

        filename = [NSString stringWithFormat:@"%@-%@.h", [aCategory className], [aCategory name]];
        if (outputPath != nil)
            filename = [outputPath stringByAppendingPathComponent:filename];

        [[resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];

        [symbolReferences release];
        [resultString release];
    }
}

@end
