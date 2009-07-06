// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#include <stdio.h>
#include <libc.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>

#import <Foundation/Foundation.h>
#import "NSString-Extensions.h"

#import "CDClassDump.h"
#import "CDTypeFormatter.h"
#import "CDSymbolReferences.h"

void print_usage(void)
{
    fprintf(stderr,
            "format-type %s\n"
            "Usage: format [options] <input file>\n"
            "\n"
            "  where options are:\n"
            "        -m        format method (default is to format ivars)\n"
            ,
            CLASS_DUMP_VERSION
       );
}

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL shouldFormatAsMethod = NO;

    int ch;
    BOOL errorFlag = NO;

    CDTypeFormatter *ivarTypeFormatter;
    CDTypeFormatter *methodTypeFormatter;

    ivarTypeFormatter = [[CDTypeFormatter alloc] init];
    [ivarTypeFormatter setShouldExpand:NO];
    [ivarTypeFormatter setShouldAutoExpand:YES];
    [ivarTypeFormatter setBaseLevel:1];
    //[ivarTypeFormatter setDelegate:self];

    methodTypeFormatter = [[CDTypeFormatter alloc] init];
    [methodTypeFormatter setShouldExpand:NO];
    [methodTypeFormatter setShouldAutoExpand:NO];
    [methodTypeFormatter setBaseLevel:0];
    //[methodTypeFormatter setDelegate:self];

    struct option longopts[] = {
        { "method", no_argument, NULL, 'm' },
        { NULL, 0, NULL, 0 },
    };

    if (argc == 1) {
        print_usage();
        exit(0);
    }

    while ( (ch = getopt_long(argc, argv, "m", longopts, NULL)) != -1) {
        switch (ch) {
          case 'm':
              shouldFormatAsMethod = YES;
              break;

          case '?':
          default:
              errorFlag = YES;
              break;
        }
    }

    if (errorFlag) {
        print_usage();
        exit(2);
    }

    if (optind < argc) {
        NSString *arg;
        NSString *input;
        NSError *error;
        NSArray *lines;
        NSUInteger count, index;
        CDTypeFormatter *formatter;

        arg = [NSString stringWithFileSystemRepresentation:argv[optind]];

        input = [[NSString alloc] initWithContentsOfFile:arg encoding:NSUTF8StringEncoding error:&error];
        lines = [input componentsSeparatedByString:@"\n"];

        count = [lines count];
        NSLog(@"%u lines", count);
        NSLog(@"%u pairs", count / 2);

        if (shouldFormatAsMethod)
            NSLog(@"Format as methods");
        else
            NSLog(@"Format as ivars");

        for (index = 0; index < count / 2; index++) {
            NSString *name, *type;
            NSString *str;

            name = [lines objectAtIndex:index * 2];
            type = [lines objectAtIndex:index * 2 + 1];
            NSLog(@"name: %@", name);
            NSLog(@"type: %@", type);

            if (shouldFormatAsMethod) {
                str = [methodTypeFormatter formatMethodName:name type:type symbolReferences:nil];
            } else {
                str = [ivarTypeFormatter formatVariable:name type:type symbolReferences:nil];
            }

            NSLog(@"str: %@", str);
        }

        [input release];
    }

    [ivarTypeFormatter release];
    [methodTypeFormatter release];

    [pool release];

    return 0;
}
