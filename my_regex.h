//
// $Id: my_regex.h,v 1.3 2000/10/15 01:22:18 nygard Exp $
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

#include <regex.h> // This is the same name for both the old and new versions.

#ifdef __APPLE_CPP__
char *my_re_comp (const char *pattern);
int my_re_exec (const char *text);
void my_re_free (void);

#define RE_COMP(pattern) my_re_comp(pattern)
#define RE_EXEC(text) my_re_exec(text)
#define RE_FREE() my_re_free()
#else
#define RE_COMP(pattern) re_comp(pattern)
#define RE_EXEC(text) re_exec(text)
#define RE_FREE() /* empty */
#endif
