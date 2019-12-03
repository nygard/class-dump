// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

// M_20191124 BlackDady Add Option Replace (regex format)

#import "CDFile.h" // For CDArch

#define CLASS_DUMP_BASE_VERSION "3.5b1 (64 bit)"

#ifdef DEBUG
#define CLASS_DUMP_VERSION CLASS_DUMP_BASE_VERSION " (Debug version compiled " __DATE__ " " __TIME__ ")"
#else
#define CLASS_DUMP_VERSION CLASS_DUMP_BASE_VERSION
#endif

@class CDFile;
@class CDTypeController;
@class CDVisitor;
@class CDSearchPathState;

@interface CDClassDump : NSObject

@property (readonly) CDSearchPathState *searchPathState;

@property (assign) BOOL shouldProcessRecursively;
@property (assign) BOOL shouldSortClasses;
@property (assign) BOOL shouldSortClassesByInheritance;
@property (assign) BOOL shouldSortMethods;
@property (assign) BOOL shouldShowIvarOffsets;
@property (assign) BOOL shouldShowMethodAddresses;
@property (assign) BOOL shouldShowHeader;


@property (strong) NSRegularExpression *regularExpression;

@property (strong) NSMutableDictionary<NSRegularExpression *, NSString *> *dictReplaceRegularExpressions; // M_20191124 END M_20191124

- (BOOL)shouldShowName:(NSString *)name;

@property (strong) NSString *sdkRoot;

@property (readonly) NSArray *machOFiles;
@property (readonly) NSArray *objcProcessors;

@property (assign) CDArch targetArch;

@property (nonatomic, readonly) BOOL containsObjectiveCData;
@property (nonatomic, readonly) BOOL hasEncryptedFiles;
@property (nonatomic, readonly) BOOL hasObjectiveCRuntimeInfo;

@property (readonly) CDTypeController *typeController;

- (BOOL)loadFile:(CDFile *)file error:(NSError **)error;
- (void)processObjectiveCData;

- (void)recursivelyVisit:(CDVisitor *)visitor;

- (void)appendHeaderToString:(NSMutableString *)resultString;

- (void)replacePartsToMutableString:(NSMutableString *)resultString; // M_20191124 END M_20191124
- (NSString *)replacePartsToString:(NSString *)txtInput; // M_20191124 END M_20191124

- (void)registerTypes;

- (void)showHeader;
- (void)showLoadCommands;

@end

extern NSString *CDErrorDomain_ClassDump;
extern NSString *CDErrorKey_Exception;


