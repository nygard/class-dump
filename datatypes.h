//
// $Id: datatypes.h,v 1.10 2003/12/17 05:53:09 nygard Exp $
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

#ifndef __DATATYPES_H
#define __DATATYPES_H

struct my_objc_type
{
    struct my_objc_type *link;
    struct my_objc_type *subtype;
    struct my_objc_type *next;
    int type;
    NSString *var_name;
    NSString *type_name;
};

#define array_size type_name
#define bitfield_size type_name

struct method_type
{
    struct method_type *link;
    struct method_type *next;
    NSString *name;
    struct my_objc_type *type;
};

//======================================================================

// Type creation functions
struct my_objc_type *create_empty_type(void); // private
struct my_objc_type *create_simple_type(int type);
struct my_objc_type *create_id_type(NSString *name);
struct my_objc_type *create_struct_type(NSString *name, struct my_objc_type *members);
struct my_objc_type *create_union_type(struct my_objc_type *members, NSString *type_name);
struct my_objc_type *create_bitfield_type(NSString *size);
struct my_objc_type *create_array_type(NSString *count, struct my_objc_type *type);
struct my_objc_type *create_pointer_type(struct my_objc_type *type);
struct my_objc_type *create_modified_type(int modifier, struct my_objc_type *type);

// Method creation functions
struct method_type *create_method_type(struct my_objc_type *t, NSString *name);

// Misc functions
struct method_type *reverse_method_types(struct method_type *m);

// Display functions
NSString *string_from_type(struct my_objc_type *t, NSString *inner, int expand, int level);
NSString *string_from_method_type(NSString *methodName, struct method_type *m);

void free_objc_type(struct my_objc_type *t);
void free_method_type(struct method_type *m);

void free_allocated_types(void);
void free_allocated_methods(void);

#endif
