//
// $Id: datatypes.m,v 1.9 2002/12/19 07:14:57 nygard Exp $
//

//
//  This file is a part of class-dump v2, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997, 1999, 2000, 2002  Steve Nygard
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

#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#import <Foundation/Foundation.h>

#include "datatypes.h"
#include "gram.h"

NSString *string_indent_to_level(int level);
NSString *string_from_members(struct my_objc_type *t, int level);
NSString *string_from_simple_type(char c);
NSString *string_from_type(struct my_objc_type *t, NSString *inner, int expand, int level);

// Not ^ or b
static char *simple_types = "cislqCISLQfdv*#:%?rnNoORV";

static char *simple_type_names[] =
{
    "char",
    "int",
    "short",
    "long",
    "long long",
    "unsigned char",
    "unsigned int",
    "unsigned short",
    "unsigned long",
    "unsigned long long",
    "float",
    "double",
    "void",
    "STR",
    "Class",
    "SEL",
    "NXAtom",
    "UNKNOWN",
    "const",
    "in",
    "inout",
    "out",
    "bycopy",
    "byref",
    "oneway"
};

struct my_objc_type *allocated_types = NULL;
struct method_type *allocated_methods = NULL;

//======================================================================
// Type creation functions
//======================================================================

struct my_objc_type *create_empty_type(void)
{
    struct my_objc_type *tmp = malloc(sizeof(struct my_objc_type));

    assert(tmp != NULL);

    tmp->link = allocated_types;
    allocated_types = tmp;

    tmp->subtype = NULL;
    tmp->next = NULL;
    tmp->type = 0;
    tmp->var_name = NULL;
    tmp->type_name = NULL;

    return tmp;
}

struct my_objc_type *create_simple_type(int type)
{
    struct my_objc_type *t = create_empty_type();

    extern int char_star_flag;

    if (char_star_flag == 1 && type == '*') {
        t->type = '^';
        t->subtype = create_simple_type('c');
    } else {
        t->type = type;
    }

    return t;
}

struct my_objc_type *create_id_type(char *name)
{
    struct my_objc_type *t = create_empty_type();

    t->type_name = name;

    if (name != NULL) {
        t->type = T_NAMED_OBJECT;
        return create_pointer_type(t);
    } else {
        t->type = '@';
    }

    return t;
}

struct my_objc_type *create_struct_type(char *name, struct my_objc_type *members)
{
    struct my_objc_type *t = create_empty_type();

    t->type = '{';
    t->type_name = name;
    t->subtype = members;

    return t;
}

struct my_objc_type *create_union_type(struct my_objc_type *members, char *type_name)
{
    struct my_objc_type *t = create_empty_type();

    t->type = '(';
    t->subtype = members;
    t->type_name = type_name;

    return t;
}

struct my_objc_type *create_bitfield_type(char *size)
{
    struct my_objc_type *t = create_empty_type();

    t->type = 'b';
    t->bitfield_size = size;

    return t;
}

struct my_objc_type *create_array_type(char *count, struct my_objc_type *type)
{
    struct my_objc_type *t = create_empty_type();

    t->type = '[';
    t->array_size = count;
    t->subtype = type;

    return t;
}

struct my_objc_type *create_pointer_type(struct my_objc_type *type)
{
    struct my_objc_type *t = create_empty_type();

    t->type = '^';
    t->subtype = type;

    return t;
}

struct my_objc_type *create_modified_type(int modifier, struct my_objc_type *type)
{
    struct my_objc_type *t = create_empty_type();

    t->type = modifier;
    t->subtype = type;

    return t;
}

//======================================================================
// Method creation functions
//======================================================================

struct method_type *create_method_type(struct my_objc_type *t, char *name)
{
    struct method_type *tmp = malloc(sizeof(struct method_type));

    assert(tmp != NULL);

    tmp->link = allocated_methods;
    allocated_methods = tmp;

    tmp->next = NULL;
    tmp->name = name;
    tmp->type = t;

    return tmp;
}

//======================================================================
// Misc functions
//======================================================================

struct my_objc_type *reverse_types(struct my_objc_type *t)
{
    struct my_objc_type *head = NULL;
    struct my_objc_type *tmp;

    while (t != NULL) {
        tmp = t;
        t = t->next;
        tmp->next = head;
        head = tmp;
    }

    return head;
}

struct method_type *reverse_method_types(struct method_type *m)
{
    struct method_type *head = NULL;
    struct method_type *tmp;

    while (m != NULL) {
        tmp = m;
        m = m->next;
        tmp->next = head;
        head = tmp;
    }

    return head;
}

//======================================================================
// Display functions
//======================================================================

void indent_to_level(int level)
{
    int l;

    for (l = 0; l < level; l++)
        printf("  ");
}

NSString *string_indent_to_level(int level)
{
    NSMutableString *str;
    int l;

    str = [NSMutableString string];
    for (l = 0; l < level; l++)
        [str appendString:@"  "];
    
    return str;
}

NSString *string_from_members (struct my_objc_type *t, int level)
{
    NSMutableString *str;

    str = [NSMutableString string];
    
    while (t != NULL) {
        [str appendString:string_indent_to_level(level)];
        [str appendString:string_from_type(t, nil, 1, level)];
        [str appendString:@";\n"];
        t = t->next;
    }

    return str;
}

NSString *string_from_simple_type(char c)
{
    char *ptr = strchr(simple_types, c);
    NSString *str = nil;

    if (ptr != NULL)
        str = [NSString stringWithFormat:@"%s", simple_type_names[ ptr - simple_types ]];
    else
        NSLog(@"Unknown simple type '%c'", c);

    return str;
}

NSString *string_from_type(struct my_objc_type *t, NSString *inner, int expand, int level)
{
    NSString *tmp;
    NSString *name, *type_name;

    if (t == NULL)
        return inner;

    if (inner == nil)
        inner = @"";

    //NSLog(@"sft: '%c', inner: '%@'", t->type, inner);

    switch (t->type) {
      case T_NAMED_OBJECT:
          if (t->var_name == NULL)
              name = @"";
          else
              name = [NSString stringWithFormat:@" %s", t->var_name];
          
          tmp = [NSString stringWithFormat:@"%s%@ %@", t->type_name, name, inner]; // We always have a pointer to this type
          break;
          
      case '@':
          if (t->var_name == NULL)
              name = @"";
          else
              name = [NSString stringWithFormat:@" %s", t->var_name];
          
          if ([inner length] > 0)
              tmp = [NSString stringWithFormat:@"id%@ %@", name, inner];
          else
              tmp = [NSString stringWithFormat:@"id%@%@", name, inner];
          break;

      case 'b':
          if (t->var_name == NULL)
              name = @"";
          else
              name = [NSString stringWithFormat:@"%s", t->var_name];

          tmp = [NSString stringWithFormat:@"int %@:%s%@", name, t->bitfield_size, inner];
          break;

      case '[':
          if (t->var_name == NULL)
              name = @"";
          else
              name = [NSString stringWithFormat:@"%s", t->var_name];

          tmp = [NSString stringWithFormat:@"%@%@[%s]", inner, name, t->array_size];
          tmp = string_from_type (t->subtype, tmp, expand, level);
          break;

      case '(':
          if (t->var_name == NULL)
              name = @"";
          else
              name = [NSString stringWithFormat:@"%s", t->var_name];

          if (t->type_name == NULL)
              type_name = @"";
          else
              type_name = [NSString stringWithFormat:@" %s", t->type_name];

          tmp = [NSString stringWithFormat:@"union%@", type_name];
          if (expand == 1 && t->subtype != NULL) {
              tmp = [NSString stringWithFormat:@"%@ {\n%@%@}", tmp, string_from_members(t->subtype, level + 1),
                              string_indent_to_level(level)];
          }

          if ([inner length] > 0 || [name length] > 0) {
              tmp = [NSString stringWithFormat:@"%@ %@%@", tmp, inner, name];
          }
          break;

      case '{':
          if (t->var_name == NULL)
              name = @"";
          else
              name = [NSString stringWithFormat:@"%s", t->var_name];

          if (t->type_name == NULL)
              type_name = @"";
          else
              type_name = [NSString stringWithFormat:@" %s", t->type_name];

          if(t->type_name != NULL && t->type_name[0] == '?')
              tmp = [NSString stringWithFormat:@"unsigned long /* WARNING: This may not be a unsigned long (%s)*/", t->type_name];
          else
              tmp = [NSString stringWithFormat:@"struct%@", type_name];

          if (expand == 1 && t->subtype != NULL) {
              tmp = [NSString stringWithFormat:@"%@ {\n%@%@}", tmp, string_from_members(t->subtype, level + 1),
                              string_indent_to_level(level)];
          }

          if ([inner length] > 0 || [name length] > 0) {
              tmp = [NSString stringWithFormat:@"%@ %@%@", tmp, inner, name];
          }
          break;

      case '^':
          if (t->var_name == NULL)
              name = @"";
          else
              name = [NSString stringWithFormat:@"%s", t->var_name];

          if (t->subtype != NULL && t->subtype->type == '[')
              tmp = [NSString stringWithFormat:@"(*%@%@)", inner, name];
          else
              tmp = [NSString stringWithFormat:@"*%@%@", name, inner];

          tmp = string_from_type(t->subtype, tmp, expand, level);
          break;

      case 'r':
      case 'n':
      case 'N':
      case 'o':
      case 'O':
      case 'R':
      case 'V':
          tmp = string_from_type(t->subtype, inner, expand, level);
          tmp = [NSString stringWithFormat:@"%@ %@", string_from_simple_type(t->type), tmp];
          break;

      default:
          if (t->var_name == NULL)
              name = @"";
          else
              name = [NSString stringWithFormat:@"%s", t->var_name];
          
          if ([name length] == 0 && [inner length] == 0)
              tmp = string_from_simple_type(t->type);
          else
              tmp = [NSString stringWithFormat:@"%@ %@%@", string_from_simple_type(t->type), name, inner];
          break;
    }

    return tmp;
}

void print_type(struct my_objc_type *t, int expand, int level)
{
    NSString *str;

    str = string_from_type(t, nil, expand, level);

    printf("%s", [str cString]);
}

void print_method(char method_type, const char *method_name, struct method_type *m)
{
    extern int expand_structures_flag;
    int l;
    BOOL noMoreTypes;

    printf("%c ", method_type);
    if (m == NULL) {
        printf("%s; /* Error: No method types. */", method_name);
        return;
    }

    noMoreTypes = NO;

    if (!IS_ID(m->type)) {
        printf("(");
        print_type(m->type, expand_structures_flag, 0);
        printf(")");
    }

    for (l = 0; l < 3 && m != NULL; l++)
        m = m->next;

    while (*method_name != '\0') {
        while (*method_name != '\0' && *method_name != ':') {
            putchar(*method_name);
            method_name++;
        }

        if (*method_name == ':') {
            printf(":");
            if (m == NULL) {
                noMoreTypes = YES;
                method_name++;
            } else {
                if (!IS_ID(m->type)) {
                    printf("(");
                    print_type(m->type, expand_structures_flag, 0);
                    printf(")");
                }
                printf("fp%s", m->name);
                method_name++;
                if (*method_name != '\0' && *method_name != ':')
                    printf(" ");
                m = m->next;
            }
        }
    }
    printf(";");

    if (noMoreTypes == YES) {
        printf(" /* Error: Ran out of types for this method. */");
    }
}

//======================================================================

void free_objc_type(struct my_objc_type *t)
{
    struct my_objc_type *tmp;

    while (t != NULL) {
        tmp = t;
        t = t->next;

        if (tmp->var_name != NULL)
            free(tmp->var_name);
        if (tmp->type_name != NULL)
            free(tmp->type_name);
        if (tmp->subtype != NULL)
            free_objc_type(tmp->subtype);
    }
}

void free_method_type(struct method_type *m)
{
    struct method_type *tmp;

    while (m != NULL) {
        tmp = m;
        m = m->next;

        if (tmp->name != NULL)
            free(tmp->name);
        free_objc_type(tmp->type);
    }
}

//======================================================================

void free_allocated_types(void)
{
    struct my_objc_type *tmp;

    while (allocated_types != NULL) {
        tmp = allocated_types;
        allocated_types = allocated_types->link;

        if (tmp->var_name != NULL)
            free(tmp->var_name);
        if (tmp->type_name != NULL)
            free(tmp->type_name);
    }
}

void free_allocated_methods(void)
{
    struct method_type *tmp;

    while (allocated_methods != NULL) {
        tmp = allocated_methods;
        allocated_methods = allocated_methods->link;

        if (tmp->name != NULL)
            free(tmp->name);
    }
}
