// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDMultiFileVisitor.h"

#import "CDClassDump.h"
#import "CDClassFrameworkVisitor.h"
#import "CDOCCategory.h"
#import "CDOCClass.h"
#import "CDOCProtocol.h"
#import "CDOCInstanceVariable.h"
#import "CDTypeController.h"

@interface CDMultiFileVisitor ()

// NSString (class name) -> NSString (framework name)
@property (strong) NSDictionary *frameworkNamesByClassName;

// NSString (protocol name) -> NSString (framework name)
@property (strong) NSDictionary *frameworkNamesByProtocolName;

// Location in output string to insert the protocol imports and forward class declarations.
// We don't know what classes and protocols will be referenced until the rest of the output is generated.
@property (assign) NSUInteger referenceLocation;

// Class and protocol references
@property (readonly) NSMutableSet *referencedClassNames;
@property (readonly) NSMutableSet *referencedProtocolNames;
@property (readonly) NSMutableSet *weaklyReferencedProtocolNames; // Protocols that can be forward-declared instead of imported

@property (nonatomic, readonly) NSArray *referencedClassNamesSortedByName;
@property (nonatomic, readonly) NSArray *referencedProtocolNamesSortedByName;
@property (nonatomic, readonly) NSArray *weaklyReferencedProtocolNamesSortedByName;

@property (nonatomic, readonly) NSString *referenceString;

@end

#pragma mark -

@implementation CDMultiFileVisitor
{
    NSString *_outputPath;
    
    NSDictionary *_frameworkNamesByClassName;
    NSMutableSet *_referencedClassNames;
    NSMutableSet *_referencedProtocolNames;
    NSUInteger _referenceLocation;
}

- (id)init;
{
    if ((self = [super init])) {
        _referencedClassNames = [[NSMutableSet alloc] init];
        _referencedProtocolNames = [[NSMutableSet alloc] init];
        _weaklyReferencedProtocolNames = [[NSMutableSet alloc] init];
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
        // TODO: (2007-06-14) Make sure this generates no output files in this case.
        NSLog(@"Warning: This file does not contain any Objective-C runtime information.");
    }
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    // First, we set up some context...
    [self.resultString setString:@""];
    [self.classDump appendHeaderToString:self.resultString];

    [self removeAllClassNameProtocolNameReferences];
    NSString *str = [self importStringForClassName:aClass.superClassName];
    if (str != nil) {
        [self.resultString appendString:str];
        [self.resultString appendString:@"\n"];
    }

    self.referenceLocation = [self.resultString length];

    // And then generate the regular output
    [super willVisitClass:aClass];
    
    [self addReferencesToProtocolNamesInArray:aClass.protocolNames];
}

- (void)didVisitClass:(CDOCClass *)aClass;
{
    // Generate the regular output
    [super didVisitClass:aClass];

    // Then insert the imports and write the file.
    [self removeReferenceToClassName:aClass.name];
    [self removeReferenceToClassName:aClass.superClassName];
    NSString *referenceString = self.referenceString;
    if (referenceString != nil)
        [self.resultString insertString:referenceString atIndex:self.referenceLocation];

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

    [self removeAllClassNameProtocolNameReferences];
    NSString *str = [self importStringForClassName:category.className];
    if (str != nil) {
        [self.resultString appendString:str];
        [self.resultString appendString:@"\n"];
    }
    self.referenceLocation = [self.resultString length];

    // And then generate the regular output
    [super willVisitCategory:category];

    [self addReferencesToProtocolNamesInArray:category.protocolNames];
}

- (void)didVisitCategory:(CDOCCategory *)category;
{
    // Generate the regular output
    [super didVisitCategory:category];

    // Then insert the imports and write the file.
    [self removeReferenceToClassName:category.className];
    NSString *referenceString = self.referenceString;
    if (referenceString != nil)
        [self.resultString insertString:referenceString atIndex:self.referenceLocation];

    NSString *filename = [NSString stringWithFormat:@"%@-%@.h", category.className, category.name];
    if (self.outputPath != nil)
        filename = [self.outputPath stringByAppendingPathComponent:filename];

    [[self.resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

- (void)willVisitProtocol:(CDOCProtocol *)protocol;
{
    [self.resultString setString:@""];
    [self.classDump appendHeaderToString:self.resultString];

    [self removeAllClassNameProtocolNameReferences];
    self.referenceLocation = [self.resultString length];

    // And then generate the regular output
    [super willVisitProtocol:protocol];

    [self addReferencesToProtocolNamesInArray:protocol.protocolNames];
}

- (void)didVisitProtocol:(CDOCProtocol *)protocol;
{
    // Generate the regular output
    [super didVisitProtocol:protocol];

    // Then insert the imports and write the file.
    NSString *referenceString = self.referenceString;
    if (referenceString != nil)
        [self.resultString insertString:referenceString atIndex:self.referenceLocation];

    NSString *filename = [NSString stringWithFormat:@"%@-Protocol.h", protocol.name];
    if (self.outputPath != nil)
        filename = [self.outputPath stringByAppendingPathComponent:filename];

    [[self.resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

#pragma mark - CDTypeControllerDelegate

- (void)typeController:(CDTypeController *)typeController didReferenceClassName:(NSString *)name;
{
    [self addReferenceToClassName:name];
}

- (void)typeController:(CDTypeController *)typeController didReferenceProtocolNames:(NSArray *)names;
{
    [self addWeakReferencesToProtocolNamesInArray:names];
}

#pragma mark -

- (NSString *)frameworkForClassName:(NSString *)name;
{
    NSString *framework = self.frameworkNamesByClassName[name];
    
    // Map public CoreFoundation classes to Foundation, because that is where the headers are exposed
    if ([framework isEqualToString:@"CoreFoundation"] && [name hasPrefix:@"NS"]) {
        framework = @"Foundation";
    }
    
    return framework;
}

- (NSString *)frameworkForProtocolName:(NSString *)name;
{
    return self.frameworkNamesByProtocolName[name];
}

- (NSString *)importStringForClassName:(NSString *)name;
{
    if (name != nil) {
        NSString *framework = [self frameworkForClassName:name];
        if (framework == nil)
            return [NSString stringWithFormat:@"#import \"%@.h\"\n", name];
        else
            return [NSString stringWithFormat:@"#import <%@/%@.h>\n", framework, name];
    }
    
    return nil;
}

- (NSString *)importStringForProtocolName:(NSString *)name;
{
    if (name != nil) {
        NSString *framework = [self frameworkForProtocolName:name];
        NSString *headerName = [name stringByAppendingString:@"-Protocol.h"];
        if (framework == nil)
            return [NSString stringWithFormat:@"#import \"%@\"\n", headerName];
        else
            return [NSString stringWithFormat:@"#import <%@/%@>\n", framework, headerName];
    }
    
    return nil;
}

#pragma mark - Class and Protocol name tracking

- (NSArray *)referencedClassNamesSortedByName;
{
    return [[self.referencedClassNames allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)referencedProtocolNamesSortedByName;
{
    return [[self.referencedProtocolNames allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)weaklyReferencedProtocolNamesSortedByName;
{
    return [[self.weaklyReferencedProtocolNames allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)addReferenceToClassName:(NSString *)className;
{
    [self.referencedClassNames addObject:className];
}

- (void)removeReferenceToClassName:(NSString *)className;
{
    if (className != nil)
        [self.referencedClassNames removeObject:className];
}

- (void)addReferencesToProtocolNamesInArray:(NSArray *)protocolNames;
{
    [self.referencedProtocolNames addObjectsFromArray:protocolNames];
}

- (void)addWeakReferencesToProtocolNamesInArray:(NSArray *)protocolNames;
{
    [self.weaklyReferencedProtocolNames addObjectsFromArray:protocolNames];
}

- (void)removeAllClassNameProtocolNameReferences;
{
    [self.referencedClassNames removeAllObjects];
    [self.referencedProtocolNames removeAllObjects];
    [self.weaklyReferencedProtocolNames removeAllObjects];
}

#pragma mark -

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

#pragma mark -

// - imports for each referenced protocol
// - forward declarations for each referenced class

- (NSString *)referenceString;
{
    NSMutableString *referenceString = [[NSMutableString alloc] init];

    if ([self.referencedProtocolNames count] > 0) {
        for (NSString *name in self.referencedProtocolNamesSortedByName) {
            NSString *str = [self importStringForProtocolName:name];
            if (str != nil)
                [referenceString appendString:str];
        }

        [referenceString appendString:@"\n"];
    }
    
    BOOL addNewline = NO;
    if ([self.referencedClassNames count] > 0) {
        [referenceString appendFormat:@"@class %@;\n", [self.referencedClassNamesSortedByName componentsJoinedByString:@", "]];
        addNewline = YES;
    }

    if ([self.weaklyReferencedProtocolNames count] > 0) {
        [referenceString appendFormat:@"@protocol %@;\n", [self.weaklyReferencedProtocolNamesSortedByName componentsJoinedByString:@", "]];
        addNewline = YES;
    }
    
    if (addNewline)
        [referenceString appendString:@"\n"];
    
    if ([referenceString length] == 0)
        return nil;
    
    return [referenceString copy];
}

#pragma mark -

- (void)buildClassFrameworks;
{
    CDClassFrameworkVisitor *visitor = [[CDClassFrameworkVisitor alloc] init];
    visitor.classDump = self.classDump;
    
    [self.classDump recursivelyVisit:visitor];
    self.frameworkNamesByClassName = visitor.frameworkNamesByClassName;
    self.frameworkNamesByProtocolName = visitor.frameworkNamesByProtocolName;
}

- (void)generateStructureHeader;
{
    [self.resultString setString:@""];
    [self.classDump appendHeaderToString:self.resultString];
    
    [self removeAllClassNameProtocolNameReferences];
    self.referenceLocation = [self.resultString length];
    
    [[self.classDump typeController] appendStructuresToString:self.resultString];
    
    NSString *referenceString = [self referenceString];
    if (referenceString != nil)
        [self.resultString insertString:referenceString atIndex:self.referenceLocation];
    
    NSString *filename = @"CDStructures.h";
    if (self.outputPath != nil)
        filename = [self.outputPath stringByAppendingPathComponent:filename];
    
    [[self.resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filename atomically:YES];
}

@end
