//
// $Id: lexer.c,v 1.6 2003/09/05 20:33:28 nygard Exp $
//

//
//  This file is a part of class-dump v2, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997, 2000  Steve Nygard
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
//
//  You may contact the author by:
//     e-mail:  class-dump at codethecode.com
//

#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include "gram.h"

#define LEX_BUFFER_SIZE 1024

int ident_state = 0;

char yytext[LEX_BUFFER_SIZE];
static const char *yyend = yytext + LEX_BUFFER_SIZE - 1;
static const char *string = NULL;
const char *scanner_ptr = NULL;

#define is_other(x) (x == '$' || x == '_' || x == ':' || x == '*')

void yy_scan_string(const char *str)
{
    scanner_ptr = string = str;
}

int yylex(void)
{
    if (ident_state == 1) {
        if (*scanner_ptr == '?') {
            scanner_ptr++;
            strcpy(yytext, "?");
            ident_state = 0;
            //fprintf(stderr, "yylex() {ident_state = 1} returning TK_IDENTIFIER, yytext = '%s'\n", yytext);
            return TK_IDENTIFIER;
        }

        if (*scanner_ptr == '"') {
            scanner_ptr++;
            ident_state = 0;
            //fprintf(stderr, "yylex() {ident_state = 1} returning '\"'\n");
            return '"';
        }

        if (isalpha(*scanner_ptr) || is_other(*scanner_ptr)) {
            char *yptr;

            yptr = yytext;
            *yptr++ = *scanner_ptr++;

            // Need bounds checking.
            while ((isalnum(*scanner_ptr) || is_other(*scanner_ptr)) && yptr < yyend) {
                *yptr++ = *scanner_ptr++;
            }
            *yptr = 0;

            ident_state = 0;
            //fprintf(stderr, "yylex() {ident_state = 1} returning TK_IDENTIFIER, yytext = '%s'\n", yytext);
            return TK_IDENTIFIER;
        }
    }

    if (isdigit(*scanner_ptr)) {
        char *yptr;

        yptr = yytext;

        while ((isdigit(*scanner_ptr)) && yptr < yyend) {
            *yptr++ = *scanner_ptr++;
        }
        *yptr = 0;
        ident_state = 0;

        //fprintf(stderr, "yylex() {ident_state = 0} returning TK_NUMBER, yytext = '%s'\n", yytext);
        return TK_NUMBER;
    }

    if (*scanner_ptr == 0) {
        //fprintf(stderr, "yylex() {ident_state = 0} returning 0\n");
        return 0;
    }

    //fprintf(stderr, "yylex() {ident_state = 0} returning '%c'\n", *scanner_ptr);
    return *scanner_ptr++;
}
