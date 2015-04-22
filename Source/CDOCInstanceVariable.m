// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDOCInstanceVariable.h"

#import "CDClassDump.h"
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"
#import "CDTypeController.h"
#import "CDType.h"

@interface CDOCInstanceVariable ()
@property (assign) BOOL hasParsedType;
@end

#pragma mark -

@implementation CDOCInstanceVariable
{
    NSString *_name;
    NSString *_typeString;
    NSUInteger _offset;
    
    BOOL _hasParsedType;
    CDType *_type;
    NSError *_parseError;
}

- (id)initWithName:(NSString *)name typeString:(NSString *)typeString offset:(NSUInteger)offset;
{
    if ((self = [super init])) {
        _name       = name;
        _typeString = typeString;
        _offset     = offset;
        
        _hasParsedType = NO;
        _type          = nil;
        _parseError    = nil;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, typeString: '%@', offset: %lu",
            NSStringFromClass([self class]), self.name, self.typeString, self.offset];
}

#pragma mark -

- (CDType *)type;
{
    if (self.hasParsedType == NO && self.parseError == nil) {
        CDTypeParser *parser = [[CDTypeParser alloc] initWithString:self.typeString];
        NSError *error;
        _type = [parser parseType:&error];
        if (_type == nil) {
            NSLog(@"Warning: Parsing instance variable type failed, %@", self.name);
            _parseError = error;
        } else {
            self.hasParsedType = YES;
        }
    }

    return _type;
}

- (void)appendToString:(NSMutableString *)resultString typeController:(CDTypeController *)typeController;
{
    CDType *type = [self type]; // Parses it, if necessary;
    if (self.parseError != nil) {
        [resultString appendFormat:@"    // Error parsing type: %@, name: %@", self.typeString, self.name];
    } else {
        NSString *formattedString = [[typeController ivarTypeFormatter] formatVariable:self.name type:type];
        NSParameterAssert(formattedString != nil);
        [resultString appendString:formattedString];
        [resultString appendString:@";"];
        if ([typeController shouldShowIvarOffsets]) {
            [resultString appendFormat:@"\t// %ld = 0x%lx", self.offset, self.offset];
        }
    }
}

@end
