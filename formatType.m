// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

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
#import "CDBalanceFormatter.h"

void print_usage(void)
{
    fprintf(stderr,
            "formatType %s\n"
            "Usage: formatType [options] <input file>\n"
            "\n"
            "  where options are:\n"
            "        -m        format method (default is to format ivars)\n"
            ,
            CLASS_DUMP_VERSION
       );
}

enum {
    CDFormatIvar = 0,
    CDFormatMethod = 1,
    CDFormatBalance = 2,
};

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSUInteger formatType = CDFormatIvar;

    int ch;
    BOOL errorFlag = NO;

    CDTypeFormatter *ivarTypeFormatter;
    CDTypeFormatter *methodTypeFormatter;
    NSUInteger index;

    ivarTypeFormatter = [[CDTypeFormatter alloc] init];
    [ivarTypeFormatter setShouldExpand:YES];
    [ivarTypeFormatter setShouldAutoExpand:YES];
    [ivarTypeFormatter setBaseLevel:0];
    //[ivarTypeFormatter setDelegate:self];

    methodTypeFormatter = [[CDTypeFormatter alloc] init];
    [methodTypeFormatter setShouldExpand:NO];
    [methodTypeFormatter setShouldAutoExpand:NO];
    [methodTypeFormatter setBaseLevel:0];
    //[methodTypeFormatter setDelegate:self];

    struct option longopts[] = {
        { "balance", no_argument, NULL, 'b' },
        { "method", no_argument, NULL, 'm' },
        { NULL, 0, NULL, 0 },
    };

    if (argc == 1) {
        print_usage();
        exit(0);
    }

    while ( (ch = getopt_long(argc, argv, "bm", longopts, NULL)) != -1) {
        switch (ch) {
          case 'b':
              formatType = CDFormatBalance;
              break;

          case 'm':
              formatType = CDFormatMethod;
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

    switch (formatType) {
      case CDFormatIvar: printf("Format as ivars\n"); break;
      case CDFormatMethod: printf("Format as methods\n"); break;
      case CDFormatBalance: printf("Format as balance\n"); break;
    }

    for (index = optind; index < argc; index++) {
        NSString *arg;
        NSString *input;
        NSError *error;
        NSArray *lines;
        CDTypeFormatter *formatter;
        NSString *name, *type;

        arg = [NSString stringWithFileSystemRepresentation:argv[index]];
        printf("======================================================================\n");
        printf("File: %s\n", argv[index]);

        input = [[NSString alloc] initWithContentsOfFile:arg encoding:NSUTF8StringEncoding error:&error];
        lines = [input componentsSeparatedByString:@"\n"];

        name = type = nil;
        for (NSString *line in lines) {
            if ([line hasPrefix:@"//"] || [line length] == 0) {
                printf("%s\n", [line UTF8String]);
                continue;
            }

            if (name == nil)
                name = line;
            else if (type == nil) {
                NSString *str;

                type = line;

                switch (formatType) {
                  case CDFormatIvar:
                      str = [ivarTypeFormatter formatVariable:name type:type symbolReferences:nil];
                      break;

                  case CDFormatMethod:
                      str = [methodTypeFormatter formatMethodName:name type:type symbolReferences:nil];
                      break;

                  case CDFormatBalance: {
                      CDBalanceFormatter *balance;

                      balance = [[CDBalanceFormatter alloc] initWithString:type];
                      str = [balance format];
                      [balance release];
                  }
                }
                if (str == nil)
                    printf("Error formatting type.\n");
                else
                    printf("%s\n", [str UTF8String]);
                printf("----------------------------------------------------------------------\n");

                name = type = nil;
            }

        }

        [input release];
    }

    [ivarTypeFormatter release];
    [methodTypeFormatter release];

    [pool release];

    return 0;
}
