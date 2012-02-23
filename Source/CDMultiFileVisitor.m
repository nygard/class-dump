// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

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
    if ((self = [super init])) {
        outputPath = nil;
    }

    return self;
}

- (void)dealloc;
{
    [outputPath release];

    [super dealloc];
}

#pragma mark -

@synthesize outputPath;

- (void)createOutputPathIfNecessary;
{
    if (outputPath != nil) {
        BOOL isDirectory;

        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:outputPath isDirectory:&isDirectory] == NO) {
            NSError *error = nil;
            BOOL result = [fileManager createDirectoryAtPath:outputPath withIntermediateDirectories:YES attributes:nil error:&error];
            if (result == NO) {
                NSLog(@"Error: Couldn't create output directory: %@", outputPath);
                NSLog(@"error: %@", error); // TODO: Test this
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
    CDClassFrameworkVisitor *visitor = [[CDClassFrameworkVisitor alloc] init];
    [visitor setClassDump:classDump];
    [classDump recursivelyVisit:visitor];
    [symbolReferences setFrameworkNamesByClassName:[visitor frameworkNamesByClassName]];
    [symbolReferences setFrameworkNamesByProtocolName:[visitor frameworkNamesByProtocolName]];
    [visitor release];
}

- (void)generateStructureHeader;
{
    [resultString setString:@""];
    [classDump appendHeaderToString:resultString];

    [symbolReferences removeAllReferences];
    referenceIndex = [resultString length];

    [[classDump typeController] appendStructuresToString:resultString symbolReferences:symbolReferences];

    NSString *referenceString = [symbolReferences referenceString];
    if (referenceString != nil)
        [resultString insertString:referenceString atIndex:referenceIndex];

    NSString *filename = @"CDStructures.h";
    if (outputPath != nil)
        filename = [outputPath stringByAppendingPathComponent:filename];

    [[resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

- (void)willBeginVisiting;
{
    [super willBeginVisiting];

    [classDump appendHeaderToString:resultString];

    if (classDump.hasObjectiveCRuntimeInfo) {
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
    // First, we set up some context...
    [resultString setString:@""];
    [classDump appendHeaderToString:resultString];

    [symbolReferences removeAllReferences];
    NSString *str = [symbolReferences importStringForClassName:[aClass superClassName]];
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
    // Generate the regular output
    [super didVisitClass:aClass];

    // Then insert the imports and write the file.
    [symbolReferences removeClassName:[aClass name]];
    [symbolReferences removeClassName:[aClass superClassName]];
    NSString *referenceString = [symbolReferences referenceString];
    if (referenceString != nil)
        [resultString insertString:referenceString atIndex:referenceIndex];

    NSString *filename = [NSString stringWithFormat:@"%@.h", [aClass name]];
    if (outputPath != nil)
        filename = [outputPath stringByAppendingPathComponent:filename];

    [[resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

- (void)willVisitCategory:(CDOCCategory *)aCategory;
{
    // First, we set up some context...
    [resultString setString:@""];
    [classDump appendHeaderToString:resultString];

    [symbolReferences removeAllReferences];
    NSString *str = [symbolReferences importStringForClassName:[aCategory className]];
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
    // Generate the regular output
    [super didVisitCategory:aCategory];

    // Then insert the imports and write the file.
    [symbolReferences removeClassName:[aCategory className]];
    NSString *referenceString = [symbolReferences referenceString];
    if (referenceString != nil)
        [resultString insertString:referenceString atIndex:referenceIndex];

    NSString *filename = [NSString stringWithFormat:@"%@-%@.h", [aCategory className], [aCategory name]];
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
    // Generate the regular output
    [super didVisitProtocol:aProtocol];

    // Then insert the imports and write the file.
    NSString *referenceString = [symbolReferences referenceString];
    if (referenceString != nil)
        [resultString insertString:referenceString atIndex:referenceIndex];

    NSString *filename = [NSString stringWithFormat:@"%@-Protocol.h", [aProtocol name]];
    if (outputPath != nil)
        filename = [outputPath stringByAppendingPathComponent:filename];

    [[resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

@end
