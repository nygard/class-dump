//
// $Id: datatypes.h,v 1.1 1999/07/31 03:32:26 nygard Exp $
//

//
//  This file is a part of class-dump v2, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997  Steve Nygard
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
//     e-mail:  nygard@telusplanet.net
//

#ifndef __DATATYPES_H
#define __DATATYPES_H

struct my_objc_type
{
    struct my_objc_type *link;
    struct my_objc_type *subtype;
    struct my_objc_type *next;
    int type;
    char *var_name;
    char *type_name;
};

#define array_size type_name
#define bitfield_size type_name

#define IS_ID(a) ((a)->type == '@' && (a)->type_name == NULL)

struct method_type
{
    struct method_type *link;
    struct method_type *next;
    char *name;
    struct my_objc_type *type;
};

// These are from gram.y:
extern void format_type (const char *type, const char *name, int level);
extern void format_method (char method_type, const char *name, const char *types);

//======================================================================

struct my_objc_type *create_empty_type (void);
struct my_objc_type *create_simple_type (int type);
struct my_objc_type *create_id_type (char *name);
struct my_objc_type *create_struct_type (char *name, struct my_objc_type *members);
struct my_objc_type *create_union_type (struct my_objc_type *members, char *type_name);
struct my_objc_type *create_bitfield_type (char *size);
struct my_objc_type *create_array_type (char *count, struct my_objc_type *type);
struct my_objc_type *create_pointer_type (struct my_objc_type *type);
struct my_objc_type *create_modified_type (int modifier, struct my_objc_type *type);

struct method_type *create_method_type (struct my_objc_type *t, char *name);

struct my_objc_type *reverse_types (struct my_objc_type *t);
struct method_type *reverse_method_types (struct method_type *m);

void indent_to_level (int level);

void print_type (struct my_objc_type *t, int expand, int level);
void print_method (char method_type, const char *method_name, struct method_type *m);

void free_objc_type (struct my_objc_type *t);
void free_method_type (struct method_type *m);

void free_allocated_types (void);
void free_allocated_methods (void);

#endif
