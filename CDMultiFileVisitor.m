// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDMultiFileVisitor.h"

#import "NSArray-Extensions.h"
#import "CDClassDump.h"
#import "CDClassFrameworkVisitor.h"
#import "CDSymbolReferences.h"
#import "CDOCClass.h"
#import "CDOCProtocol.h"
#import "CDOCIvar.h"
#import "CDTypeController.h"

@implementation CDMultiFileVisitor

- (id)init;
{
    if ([super init] == nil)
        return nil;

    outputPath = nil;

    return self;
}

- (void)dealloc;
{
    [outputPath release];

    [super dealloc];
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
    CDClassFrameworkVisitor *visitor;

    visitor = [[CDClassFrameworkVisitor alloc] init];
    [visitor setClassDump:classDump];
    [classDump recursivelyVisit:visitor];
    [symbolReferences setFrameworkNamesByClassName:[visitor frameworkNamesByClassName]];
    [symbolReferences setFrameworkNamesByProtocolName:[visitor frameworkNamesByProtocolName]];
    [visitor release];
}

- (void)generateStructureHeader;
{
    NSString *filename;
    NSString *referenceString;

    [resultString setString:@""];
    [classDump appendHeaderToString:resultString];

    [symbolReferences removeAllReferences];
    referenceIndex = [resultString length];

    [[classDump typeController] appendStructuresToString:resultString symbolReferences:symbolReferences];

    referenceString = [symbolReferences referenceString];
    if (referenceString != nil)
        [resultString insertString:referenceString atIndex:referenceIndex];

    filename = @"CDStructures.h";
    if (outputPath != nil)
        filename = [outputPath stringByAppendingPathComponent:filename];

    [[resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

- (void)willBeginVisiting;
{
    [super willBeginVisiting];

    [classDump appendHeaderToString:resultString];

    if ([classDump containsObjectiveCData] || [classDump hasEncryptedFiles]) {
        [self buildClassFrameworks];
        [self createOutputPathIfNecessary];
        [self generateStructureHeader];
    } else {
        // TODO (2007-06-14): Make sure this generates no output files in this case.
        NSLog(@"Warning: This file does not contain any Objective-C runtime information.");
    }
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    NSString *str;

    // First, we set up some context...
    [resultString setString:@""];
    [classDump appendHeaderToString:resultString];

    [symbolReferences removeAllReferences];
    str = [symbolReferences importStringForClassName:[aClass superClassName]];
    if (str != nil) {
        [resultString appendString:str];
        [resultString appendString:@"\n"];
    }

    referenceIndex = [resultString length];

    // And then generate the regular output
    [super willVisitClass:aClass];
}

- (void)didVisitClass:(CDOCClass *)aClass;
{
    NSString *referenceString;
    NSString *filename;

    // Generate the regular output
    [super didVisitClass:aClass];

    // Then insert the imports and write the file.
    [symbolReferences removeClassName:[aClass name]];
    [symbolReferences removeClassName:[aClass superClassName]];
    referenceString = [symbolReferences referenceString];
    if (referenceString != nil)
        [resultString insertString:referenceString atIndex:referenceIndex];

    filename = [NSString stringWithFormat:@"%@.h", [aClass name]];
    if (outputPath != nil)
        filename = [outputPath stringByAppendingPathComponent:filename];

    [[resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

- (void)willVisitCategory:(CDOCCategory *)aCategory;
{
    NSString *str;

    // First, we set up some context...
    [resultString setString:@""];
    [classDump appendHeaderToString:resultString];

    [symbolReferences removeAllReferences];
    str = [symbolReferences importStringForClassName:[aCategory className]];
    if (str != nil) {
        [resultString appendString:str];
        [resultString appendString:@"\n"];
    }
    referenceIndex = [resultString length];

    // And then generate the regular output
    [super willVisitCategory:aCategory];
}

- (void)didVisitCategory:(CDOCCategory *)aCategory;
{
    NSString *referenceString;
    NSString *filename;

    // Generate the regular output
    [super didVisitCategory:aCategory];

    // Then insert the imports and write the file.
    [symbolReferences removeClassName:[aCategory className]];
    referenceString = [symbolReferences referenceString];
    if (referenceString != nil)
        [resultString insertString:referenceString atIndex:referenceIndex];

    filename = [NSString stringWithFormat:@"%@-%@.h", [aCategory className], [aCategory name]];
    if (outputPath != nil)
        filename = [outputPath stringByAppendingPathComponent:filename];

    [[resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

- (void)willVisitProtocol:(CDOCProtocol *)aProtocol;
{
    [resultString setString:@""];
    [classDump appendHeaderToString:resultString];

    [symbolReferences removeAllReferences];
    referenceIndex = [resultString length];

    // And then generate the regular output
    [super willVisitProtocol:aProtocol];
}

- (void)didVisitProtocol:(CDOCProtocol *)aProtocol;
{
    NSString *referenceString;
    NSString *filename;

    // Generate the regular output
    [super didVisitProtocol:aProtocol];

    // Then insert the imports and write the file.
    referenceString = [symbolReferences referenceString];
    if (referenceString != nil)
        [resultString insertString:referenceString atIndex:referenceIndex];

    filename = [NSString stringWithFormat:@"%@-Protocol.h", [aProtocol name]];
    if (outputPath != nil)
        filename = [outputPath stringByAppendingPathComponent:filename];

    [[resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

@end
