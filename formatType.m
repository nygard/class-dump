// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#include <stdio.h>
#include <libc.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>

#import "CDClassDump.h"
#import "CDTypeFormatter.h"
#import "CDBalanceFormatter.h"
#import "CDOCInstanceVariable.h"

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

typedef enum : NSUInteger {
    CDFormat_Ivar    = 0,
    CDFormat_Method  = 1,
    CDFormat_Balance = 2,
} CDFormatType;

int main(int argc, char *argv[])
{
    @autoreleasepool {
        CDTypeFormatter *ivarTypeFormatter = [[CDTypeFormatter alloc] init];
        ivarTypeFormatter.shouldExpand = YES;
        ivarTypeFormatter.shouldAutoExpand = YES;
        ivarTypeFormatter.baseLevel = 0;

        CDTypeFormatter *methodTypeFormatter = [[CDTypeFormatter alloc] init];
        methodTypeFormatter.shouldExpand = NO;
        methodTypeFormatter.shouldAutoExpand = NO;
        methodTypeFormatter.baseLevel = 0;

        struct option longopts[] = {
            { "balance", no_argument, NULL, 'b' },
            { "method", no_argument, NULL, 'm' },
            { NULL, 0, NULL, 0 },
        };

        if (argc == 1) {
            print_usage();
            exit(0);
        }

        NSUInteger formatType = CDFormat_Ivar;
        
        BOOL errorFlag = NO;
        int ch;

        while ( (ch = getopt_long(argc, argv, "bm", longopts, NULL)) != -1) {
            switch (ch) {
                case 'b':
                    formatType = CDFormat_Balance;
                    break;
                    
                case 'm':
                    formatType = CDFormat_Method;
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
            case CDFormat_Ivar:    printf("Format as ivars\n"); break;
            case CDFormat_Method:  printf("Format as methods\n"); break;
            case CDFormat_Balance: printf("Format as balance\n"); break;
        }

        for (NSUInteger index = optind; index < (NSUInteger)argc; index++) {

            NSString *arg = [NSString stringWithFileSystemRepresentation:argv[index]];
            printf("======================================================================\n");
            printf("File: %s\n", argv[index]);

            NSError *error = nil;
            NSString *input = [[NSString alloc] initWithContentsOfFile:arg encoding:NSUTF8StringEncoding error:&error];
            if (error != nil) {
                NSLog(@"input error: %@", error);
                NSLog(@"localizedFailureReason: %@", [error localizedFailureReason]);
            }

            NSArray *lines = [input componentsSeparatedByString:@"\n"];

            NSString *name = nil;
            NSString *type = nil;
            for (NSString *line in lines) {
                if ([line hasPrefix:@"//"] || [line length] == 0) {
                    printf("%s\n", [line UTF8String]);
                    continue;
                }

                if (name == nil) {
                    name = line;
                } else if (type == nil) {
                    NSString *str;

                    type = line;

                    switch (formatType) {
                        case CDFormat_Ivar: {
                            CDOCInstanceVariable *var = [[CDOCInstanceVariable alloc] initWithName:name typeString:type offset:0];
                            str = [ivarTypeFormatter formatVariable:name type:var.type];
                            break;
                        }
                            
                        case CDFormat_Method:
                            str = [methodTypeFormatter formatMethodName:name typeString:type];
                            break;
                            
                        case CDFormat_Balance: {
                            CDBalanceFormatter *balance = [[CDBalanceFormatter alloc] initWithString:type];
                            str = [balance format];
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
        }
    }

    return 0;
}
