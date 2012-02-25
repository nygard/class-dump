// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDMultiFileVisitor.h"

#import "CDClassDump.h"
#import "CDClassFrameworkVisitor.h"
#import "CDSymbolReferences.h"
#import "CDOCCategory.h"
#import "CDOCClass.h"
#import "CDOCProtocol.h"
#import "CDOCIvar.h"
#import "CDTypeController.h"

@interface CDMultiFileVisitor ()
- (void)createOutputPathIfNecessary;
- (void)buildClassFrameworks;
- (void)generateStructureHeader;
@end

#pragma mark -

@implementation CDMultiFileVisitor
{
    NSString *outputPath;
    NSUInteger referenceIndex;
}

#pragma mark -

- (void)willBeginVisiting;
{
    [super willBeginVisiting];

    [self.classDump appendHeaderToString:self.resultString];

    if (self.classDump.hasObjectiveCRuntimeInfo) {
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
    [self.resultString setString:@""];
    [self.classDump appendHeaderToString:self.resultString];

    [self.symbolReferences removeAllReferences];
    NSString *str = [self.symbolReferences importStringForClassName:aClass.superClassName];
    if (str != nil) {
        [self.resultString appendString:str];
        [self.resultString appendString:@"\n"];
    }

    referenceIndex = [self.resultString length];

    // And then generate the regular output
    [super willVisitClass:aClass];
}

- (void)didVisitClass:(CDOCClass *)aClass;
{
    // Generate the regular output
    [super didVisitClass:aClass];

    // Then insert the imports and write the file.
    [self.symbolReferences removeClassName:aClass.name];
    [self.symbolReferences removeClassName:aClass.superClassName];
    NSString *referenceString = self.symbolReferences.referenceString;
    if (referenceString != nil)
        [self.resultString insertString:referenceString atIndex:referenceIndex];

    NSString *filename = [NSString stringWithFormat:@"%@.h", aClass.name];
    if (outputPath != nil)
        filename = [outputPath stringByAppendingPathComponent:filename];

    [[self.resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

- (void)willVisitCategory:(CDOCCategory *)category;
{
    // First, we set up some context...
    [self.resultString setString:@""];
    [self.classDump appendHeaderToString:self.resultString];

    [self.symbolReferences removeAllReferences];
    NSString *str = [self.symbolReferences importStringForClassName:category.className];
    if (str != nil) {
        [self.resultString appendString:str];
        [self.resultString appendString:@"\n"];
    }
    referenceIndex = [self.resultString length];

    // And then generate the regular output
    [super willVisitCategory:category];
}

- (void)didVisitCategory:(CDOCCategory *)category;
{
    // Generate the regular output
    [super didVisitCategory:category];

    // Then insert the imports and write the file.
    [self.symbolReferences removeClassName:category.className];
    NSString *referenceString = self.symbolReferences.referenceString;
    if (referenceString != nil)
        [self.resultString insertString:referenceString atIndex:referenceIndex];

    NSString *filename = [NSString stringWithFormat:@"%@-%@.h", category.className, category.name];
    if (outputPath != nil)
        filename = [outputPath stringByAppendingPathComponent:filename];

    [[self.resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

- (void)willVisitProtocol:(CDOCProtocol *)protocol;
{
    [self.resultString setString:@""];
    [self.classDump appendHeaderToString:self.resultString];

    [self.symbolReferences removeAllReferences];
    referenceIndex = [self.resultString length];

    // And then generate the regular output
    [super willVisitProtocol:protocol];
}

- (void)didVisitProtocol:(CDOCProtocol *)protocol;
{
    // Generate the regular output
    [super didVisitProtocol:protocol];

    // Then insert the imports and write the file.
    NSString *referenceString = self.symbolReferences.referenceString;
    if (referenceString != nil)
        [self.resultString insertString:referenceString atIndex:referenceIndex];

    NSString *filename = [NSString stringWithFormat:@"%@-Protocol.h", protocol.name];
    if (outputPath != nil)
        filename = [outputPath stringByAppendingPathComponent:filename];

    [[self.resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
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
    [visitor setClassDump:self.classDump];
    [self.classDump recursivelyVisit:visitor];
    self.symbolReferences.frameworkNamesByClassName = [visitor.frameworkNamesByClassName copy];
    self.symbolReferences.frameworkNamesByProtocolName = [visitor.frameworkNamesByProtocolName copy];
}

- (void)generateStructureHeader;
{
    [self.resultString setString:@""];
    [self.classDump appendHeaderToString:self.resultString];
    
    [self.symbolReferences removeAllReferences];
    referenceIndex = [self.resultString length];
    
    [[self.classDump typeController] appendStructuresToString:self.resultString symbolReferences:self.symbolReferences];
    
    NSString *referenceString = [self.symbolReferences referenceString];
    if (referenceString != nil)
        [self.resultString insertString:referenceString atIndex:referenceIndex];
    
    NSString *filename = @"CDStructures.h";
    if (outputPath != nil)
        filename = [outputPath stringByAppendingPathComponent:filename];
    
    [[self.resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

@end
