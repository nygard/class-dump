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
#import "CDSymbolReferences.h"

@interface CDMultiFileVisitor ()
@property (assign) NSUInteger referenceIndex;
@property (readonly) CDSymbolReferences *symbolReferences;
- (void)createOutputPathIfNecessary;
- (void)buildClassFrameworks;
- (void)generateStructureHeader;
@end

#pragma mark -

@implementation CDMultiFileVisitor
{
    NSString *_outputPath;
    NSUInteger _referenceIndex;
    CDSymbolReferences *_symbolReferences;
}

- (id)init;
{
    if ((self = [super init])) {
        _symbolReferences = [[CDSymbolReferences alloc] init];
    }
    
    return self;
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

    self.referenceIndex = [self.resultString length];

    // And then generate the regular output
    [super willVisitClass:aClass];
    
    [self.symbolReferences addProtocolNamesFromArray:aClass.protocolNames];
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
        [self.resultString insertString:referenceString atIndex:self.referenceIndex];

    NSString *filename = [NSString stringWithFormat:@"%@.h", aClass.name];
    if (self.outputPath != nil)
        filename = [self.outputPath stringByAppendingPathComponent:filename];

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
    self.referenceIndex = [self.resultString length];

    // And then generate the regular output
    [super willVisitCategory:category];

    [self.symbolReferences addProtocolNamesFromArray:category.protocolNames];
}

- (void)didVisitCategory:(CDOCCategory *)category;
{
    // Generate the regular output
    [super didVisitCategory:category];

    // Then insert the imports and write the file.
    [self.symbolReferences removeClassName:category.className];
    NSString *referenceString = self.symbolReferences.referenceString;
    if (referenceString != nil)
        [self.resultString insertString:referenceString atIndex:self.referenceIndex];

    NSString *filename = [NSString stringWithFormat:@"%@-%@.h", category.className, category.name];
    if (self.outputPath != nil)
        filename = [self.outputPath stringByAppendingPathComponent:filename];

    [[self.resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

- (void)willVisitProtocol:(CDOCProtocol *)protocol;
{
    [self.resultString setString:@""];
    [self.classDump appendHeaderToString:self.resultString];

    [self.symbolReferences removeAllReferences];
    self.referenceIndex = [self.resultString length];

    // And then generate the regular output
    [super willVisitProtocol:protocol];

    [self.symbolReferences addProtocolNamesFromArray:protocol.protocolNames];
}

- (void)didVisitProtocol:(CDOCProtocol *)protocol;
{
    // Generate the regular output
    [super didVisitProtocol:protocol];

    // Then insert the imports and write the file.
    NSString *referenceString = self.symbolReferences.referenceString;
    if (referenceString != nil)
        [self.resultString insertString:referenceString atIndex:self.referenceIndex];

    NSString *filename = [NSString stringWithFormat:@"%@-Protocol.h", protocol.name];
    if (self.outputPath != nil)
        filename = [self.outputPath stringByAppendingPathComponent:filename];

    [[self.resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

#pragma mark -

@synthesize outputPath = _outputPath;

- (void)createOutputPathIfNecessary;
{
    if (self.outputPath != nil) {
        BOOL isDirectory;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:self.outputPath isDirectory:&isDirectory] == NO) {
            NSError *error = nil;
            BOOL result = [fileManager createDirectoryAtPath:self.outputPath withIntermediateDirectories:YES attributes:nil error:&error];
            if (result == NO) {
                NSLog(@"Error: Couldn't create output directory: %@", self.outputPath);
                NSLog(@"error: %@", error); // TODO: Test this
                return;
            }
        } else if (isDirectory == NO) {
            NSLog(@"Error: File exists at output path: %@", self.outputPath);
            return;
        }
    }
}

@synthesize referenceIndex = _referenceIndex;

@synthesize symbolReferences = _symbolReferences;

- (void)buildClassFrameworks;
{
    CDClassFrameworkVisitor *visitor = [[CDClassFrameworkVisitor alloc] init];
    visitor.classDump = self.classDump;
    visitor.symbolReferences = self.symbolReferences;
    
    [self.classDump recursivelyVisit:visitor];
}

- (void)generateStructureHeader;
{
    [self.resultString setString:@""];
    [self.classDump appendHeaderToString:self.resultString];
    
    [self.symbolReferences removeAllReferences];
    self.referenceIndex = [self.resultString length];
    
    [[self.classDump typeController] appendStructuresToString:self.resultString];
    
    NSString *referenceString = [self.symbolReferences referenceString];
    if (referenceString != nil)
        [self.resultString insertString:referenceString atIndex:self.referenceIndex];
    
    NSString *filename = @"CDStructures.h";
    if (self.outputPath != nil)
        filename = [self.outputPath stringByAppendingPathComponent:filename];
    
    [[self.resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

#pragma mark - CDTypeControllerDelegate

- (void)typeController:(CDTypeController *)typeController didReferenceClassName:(NSString *)name;
{
    [self.symbolReferences addClassName:name];
}

@end
