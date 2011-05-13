//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDClassDump-XML.h"

#import <Cocoa/Cocoa.h>

NSString *CDClassDumpVersion1PublicID = @"-//codethecode.com//DTD class-dump Development 1//EN";
//NSString *CDClassDumpVersion1SystemID = @"http://www.codethecode.com/formats/class-dump-v1.dtd";
NSString *CDClassDumpVersion1SystemID = @"class-dump-v1.dtd";

@implementation CDClassDump (XML)

+ (NSString *)currentPublicID;
{
    return CDClassDumpVersion1PublicID;
}

+ (NSString *)currentSystemID;
{
    return CDClassDumpVersion1SystemID;
}

@end
