//
// $Id: my_regex.c,v 1.4 2002/12/19 07:19:31 nygard Exp $
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
//     e-mail:  nygard@omnigroup.com
//

#include <stdio.h>
#include <sys/types.h>

#import "my_regex.h"

//
// This provides functions compatible with the interface of the old style
// regular expression matching functions.  Note, however, that we use the
// extended regular expression syntax.
//

static regex_t compiled_regex;
static char regex_error_buffer[256];

char *my_re_comp(const char *pattern)
{
    int result;

    result = regcomp(&compiled_regex, pattern, REG_EXTENDED);
    if (result != 0) {
        regerror(result, &compiled_regex, regex_error_buffer, sizeof(regex_error_buffer));
        return regex_error_buffer;
    }

    return NULL;
}

int my_re_exec(const char *text)
{
    int result;

    result = regexec(&compiled_regex, text, 0, NULL, 0);

    return (result == 0) ? 1 : 0;
}

void my_re_free(void)
{
    regfree(&compiled_regex);
}
