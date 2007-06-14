//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "CDMultiFileGenerator.h"

#import "CDClassDump.h"
#import "CDSymbolReferences.h"
#import "CDOCModule.h"
#import "CDOCSymtab.h"
#import "CDObjCSegmentProcessor.h"
#import "CDMachOFile.h"

@implementation CDMultiFileGenerator

- (id)init;
{
    if ([super init] == nil)
        return nil;

    classDump = nil;
    outputPath = nil;
    frameworkNamesByClassName = [[NSMutableDictionary alloc] init];

    return self;
}

- (void)dealloc;
{
    [classDump release];
    [outputPath release];
    [frameworkNamesByClassName release];

    [super dealloc];
}

- (CDClassDump *)classDump;
{
    return classDump;
}

- (void)setClassDump:(CDClassDump *)newClassDump;
{
    if (newClassDump == classDump)
        return;

    [classDump release];
    classDump = [newClassDump retain];
}

- (NSString *)outputPath;
{
    return outputPath;
}

- (void)setOutputPath:(NSString *)newOutputPath;
{
    if (newOutputPath == outputPath)
        return;

    [outputPath release];
    outputPath = [newOutputPath retain];
}

- (void)createOutputPathIfNecessary;
{
    if (outputPath != nil) {
        NSFileManager *fileManager;
        BOOL isDirectory;

        fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:outputPath isDirectory:&isDirectory] == NO) {
            BOOL result;

            result = [fileManager createDirectoryAtPath:outputPath attributes:nil];
            if (result == NO) {
                NSLog(@"Error: Couldn't create output directory: %@", outputPath);
                return;
            }
        } else if (isDirectory == NO) {
            NSLog(@"Error: File exists at output path: %@", outputPath);
            return;
        }
    }
}

- (void)buildClassFrameworks;
{
    NSArray *objCSegmentProcessors;
    unsigned int spCount, spIndex;

    objCSegmentProcessors = [classDump objCSegmentProcessors];
    spCount = [objCSegmentProcessors count];
    for (spIndex = 0; spIndex < spCount; spIndex++) {
        CDObjCSegmentProcessor *objCSegmentProcessor;
        NSString *importBaseName;

        objCSegmentProcessor = [objCSegmentProcessors objectAtIndex:spIndex];
        importBaseName = [[objCSegmentProcessor machOFile] importBaseName];
        if (importBaseName != nil) {
            NSArray *modules;
            int moduleCount, moduleIndex;

            modules = [objCSegmentProcessor modules];
            moduleCount = [modules count];
            for (moduleIndex = 0; moduleIndex < moduleCount; moduleIndex++) {
                [[[modules objectAtIndex:moduleIndex] symtab] registerClassesWithObject:frameworkNamesByClassName frameworkName:importBaseName];
            }

            // TODO (2007-06-14): Categories could be in a different framework... register them separately?
        }
    }
}

- (NSString *)frameworkForClassName:(NSString *)aClassName;
{
    return [frameworkNamesByClassName objectForKey:aClassName];
}

- (void)appendImportForClassName:(NSString *)aClassName toString:(NSMutableString *)resultString;
{
    if (aClassName != nil) {
        NSString *classFramework;

        classFramework = [self frameworkForClassName:aClassName];
        if (classFramework == nil)
            [resultString appendFormat:@"#import \"%@.h\"\n\n", aClassName];
        else
            [resultString appendFormat:@"#import <%@/%@.h>\n\n", classFramework, aClassName];
    }
}

- (void)generateStructureHeader;
{
    NSMutableString *resultString;
    NSString *filename;
    CDSymbolReferences *symbolReferences;
    NSString *referenceString;
    unsigned int referenceIndex;

    resultString = [[NSMutableString alloc] init];
    [classDump appendHeaderToString:resultString];

    symbolReferences = [[CDSymbolReferences alloc] init];
    referenceIndex = [resultString length];

    [classDump appendStructuresToString:resultString symbolReferences:symbolReferences];

    referenceString = [symbolReferences referenceString];
    if (referenceString != nil)
        [resultString insertString:referenceString atIndex:referenceIndex];

    filename = @"CDStructures.h";
    if (outputPath != nil)
        filename = [outputPath stringByAppendingPathComponent:filename];

    [[resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];

    [symbolReferences release];
    [resultString release];
}

- (void)generateOutput;
{
    NSArray *objCSegmentProcessors;
    int count, index;

    if ([classDump containsObjectiveCSegments] == NO) {
        NSLog(@"Warning: This file does not contain any Objective-C runtime information.");
        return;
    }

    [self buildClassFrameworks];
    [self createOutputPathIfNecessary];
    [self generateStructureHeader];

    // Need to get all symtabs and call -generateSeparateheadersForSymtab on them.  Or just visit symtabs.
    objCSegmentProcessors = [classDump objCSegmentProcessors];
    count = [objCSegmentProcessors count];
    for (index = 0; index < count; index++) {
        //[[objCSegmentProcessors objectAtIndex:index] generateSeparateHeadersClassDump:self];
    }
}

- (void)generateSeparateHeadersForSymtab:(CDOCSymtab *)aSymtab;
{
#if 0
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
#endif
}

@end
