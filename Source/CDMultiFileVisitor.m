// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDMultiFileVisitor.h"

#import "CDClassDump.h"
#import "CDClassFrameworkVisitor.h"
#import "CDOCCategory.h"
#import "CDOCClass.h"
#import "CDOCProtocol.h"
#import "CDOCIvar.h"
#import "CDTypeController.h"

@interface CDMultiFileVisitor ()
@property (assign) NSUInteger referenceIndex;

// NSString (class name) -> NSString (framework name)
@property (strong) NSDictionary *frameworkNamesByClassName;

- (void)createOutputPathIfNecessary;
- (void)buildClassFrameworks;
- (void)generateStructureHeader;

// Formerly CDSymbolReferences

@property (readonly) NSMutableSet *classes;
@property (readonly) NSMutableSet *protocols;

@property (nonatomic, readonly) NSArray *classesSortedByName;
@property (nonatomic, readonly) NSArray *protocolsSortedByName;

- (void)_appendToString:(NSMutableString *)resultString;



- (void)addClassName:(NSString *)className;
- (void)removeClassName:(NSString *)className;

- (void)addProtocolNamesFromArray:(NSArray *)protocolNames;

@property (nonatomic, readonly) NSString *referenceString;

- (void)removeAllReferences;
- (NSString *)importStringForClassName:(NSString *)className;

@end

#pragma mark -

@implementation CDMultiFileVisitor
{
    NSString *_outputPath;
    NSUInteger _referenceIndex;
    
    NSDictionary *_frameworkNamesByClassName;
    NSMutableSet *_classes;
    NSMutableSet *_protocols;
}

- (id)init;
{
    if ((self = [super init])) {
        _classes = [[NSMutableSet alloc] init];
        _protocols = [[NSMutableSet alloc] init];
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

    [self removeAllReferences];
    NSString *str = [self importStringForClassName:aClass.superClassName];
    if (str != nil) {
        [self.resultString appendString:str];
        [self.resultString appendString:@"\n"];
    }

    self.referenceIndex = [self.resultString length];

    // And then generate the regular output
    [super willVisitClass:aClass];
    
    [self addProtocolNamesFromArray:aClass.protocolNames];
}

- (void)didVisitClass:(CDOCClass *)aClass;
{
    // Generate the regular output
    [super didVisitClass:aClass];

    // Then insert the imports and write the file.
    [self removeClassName:aClass.name];
    [self removeClassName:aClass.superClassName];
    NSString *referenceString = self.referenceString;
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

    [self removeAllReferences];
    NSString *str = [self importStringForClassName:category.className];
    if (str != nil) {
        [self.resultString appendString:str];
        [self.resultString appendString:@"\n"];
    }
    self.referenceIndex = [self.resultString length];

    // And then generate the regular output
    [super willVisitCategory:category];

    [self addProtocolNamesFromArray:category.protocolNames];
}

- (void)didVisitCategory:(CDOCCategory *)category;
{
    // Generate the regular output
    [super didVisitCategory:category];

    // Then insert the imports and write the file.
    [self removeClassName:category.className];
    NSString *referenceString = self.referenceString;
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

    [self removeAllReferences];
    self.referenceIndex = [self.resultString length];

    // And then generate the regular output
    [super willVisitProtocol:protocol];

    [self addProtocolNamesFromArray:protocol.protocolNames];
}

- (void)didVisitProtocol:(CDOCProtocol *)protocol;
{
    // Generate the regular output
    [super didVisitProtocol:protocol];

    // Then insert the imports and write the file.
    NSString *referenceString = self.referenceString;
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

@synthesize frameworkNamesByClassName = _frameworkNamesByClassName;

- (NSString *)frameworkForClassName:(NSString *)className;
{
    return [self.frameworkNamesByClassName objectForKey:className];
}

#pragma mark -

- (void)buildClassFrameworks;
{
    CDClassFrameworkVisitor *visitor = [[CDClassFrameworkVisitor alloc] init];
    visitor.classDump = self.classDump;
    
    [self.classDump recursivelyVisit:visitor];
    self.frameworkNamesByClassName = visitor.frameworkNamesByClassName;
}

- (void)generateStructureHeader;
{
    [self.resultString setString:@""];
    [self.classDump appendHeaderToString:self.resultString];
    
    [self removeAllReferences];
    self.referenceIndex = [self.resultString length];
    
    [[self.classDump typeController] appendStructuresToString:self.resultString];
    
    NSString *referenceString = [self referenceString];
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
    [self addClassName:name];
}

#pragma mark - Formerly CDSymbolReferences

- (void)addClassName:(NSString *)className;
{
    [self.classes addObject:className];
}

- (void)removeClassName:(NSString *)className;
{
    if (className != nil)
        [self.classes removeObject:className];
}

- (void)addProtocolNamesFromArray:(NSArray *)protocolNames;
{
    [self.protocols addObjectsFromArray:protocolNames];
}

- (NSString *)referenceString;
{
    NSMutableString *referenceString = [[NSMutableString alloc] init];
    [self _appendToString:referenceString];
    
    if ([referenceString length] == 0)
        return nil;
    
    return [referenceString copy];
}

- (void)removeAllReferences;
{
    [self.classes removeAllObjects];
    [self.protocols removeAllObjects];
}

- (NSString *)importStringForClassName:(NSString *)className;
{
    if (className != nil) {
        NSString *framework = [self frameworkForClassName:className];
        if (framework == nil)
            return [NSString stringWithFormat:@"#import \"%@.h\"\n", className];
        else
            return [NSString stringWithFormat:@"#import <%@/%@.h>\n", framework, className];
    }
    
    return nil;
}

#pragma mark -

@synthesize classes = _classes;
@synthesize protocols = _protocols;

- (NSArray *)classesSortedByName;
{
    return [[self.classes allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)protocolsSortedByName;
{
    return [[self.protocols allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)_appendToString:(NSMutableString *)resultString;
{
    if ([self.protocols count] > 0) {
        [resultString appendFormat:@"@protocol %@;\n\n", [self.protocolsSortedByName componentsJoinedByString:@", "]];
    }
    
    if ([self.classes count] > 0) {
        [resultString appendFormat:@"@class %@;\n\n", [self.classesSortedByName componentsJoinedByString:@", "]];
    }
}


@end
