// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDOCIvar.h"

#import "CDClassDump.h"
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"
#import "CDTypeController.h"
#import "CDType.h"

@interface CDOCIvar ()
@property (assign) BOOL hasParsedType; // Private
@end

#pragma mark -

@implementation CDOCIvar
{
    NSString *_name;
    NSString *_type;
    NSUInteger _offset;
    
    BOOL _hasParsedType;
    CDType *_parsedType;
}

- (id)initWithName:(NSString *)name type:(NSString *)type offset:(NSUInteger)offset;
{
    if ((self = [super init])) {
        _name = name;
        _type = type;
        _offset = offset;
        
        _hasParsedType = NO;
        _parsedType = nil;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, type: '%@', offset: %lu",
            NSStringFromClass([self class]), self.name, self.type, self.offset];
}

#pragma mark -

- (CDType *)parsedType;
{
    if (self.hasParsedType == NO) {
        NSError *error = nil;

        CDTypeParser *parser = [[CDTypeParser alloc] initWithType:self.type];
        _parsedType = [parser parseType:&error];
        if (_parsedType == nil)
            NSLog(@"Warning: Parsing ivar type failed, %@", self.name);

        self.hasParsedType = YES;
    }

    return _parsedType;
}

- (void)appendToString:(NSMutableString *)resultString typeController:(CDTypeController *)typeController;
{
    NSString *formattedString = [[typeController ivarTypeFormatter] formatVariable:self.name type:self.type];
    if (formattedString != nil) {
        [resultString appendString:formattedString];
        [resultString appendString:@";"];
        if ([typeController shouldShowIvarOffsets]) {
            [resultString appendFormat:@"\t// %ld = 0x%lx", self.offset, self.offset];
        }
    } else
        [resultString appendFormat:@"    // Error parsing type: %@, name: %@", self.type, self.name];
}

@end
