//
// $Id: class-dump.h,v 1.1 1999/07/31 03:32:26 nygard Exp $
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

#ifndef __CLASS_DUMP_H
#define __CLASS_DUMP_H

struct my_objc_module
{
    long version;
    long size;
    long name;
    long symtab;
};

// Section: __symbols
struct my_objc_symtab
{
    long sel_ref_cnt;
    long refs;
    short cls_def_count;
    short cat_def_count;
    long class_pointer;
};

// Section: __class
struct my_objc_class
{
    long isa;
    long super_class;
    long name;
    long version;
    long info;
    long instance_size;
    long ivars;
    long methods;
    long cache;
    long protocols;
};

// Section: ??
struct my_objc_category
{
    long category_name;
    long class_name;
    long methods;
    long class_methods;
    long protocols;
};

// Section: __instance_vars
struct my_objc_ivars
{
    long ivar_count;
    // Followed by ivars
};

// Section: __instance_vars
struct my_objc_ivar
{
    long name;
    long type;
    long offset;
};

// Section: __inst_meth
struct my_objc_methods
{
    long _obsolete;
    long method_count;
    // Followed by methods
};

// Section: __inst_meth
struct my_objc_method
{
    long name;
    long types;
    long imp;
};

// Section: __meta_class
struct my_objc_isa
{
};

struct my_objc_protocol_list
{
    long next;
    long count;
    long list;
};

struct my_objc_protocol
{
    long isa;
    long protocol_name;
    long protocol_list;
    long instance_methods;
};

struct my_objc_prot_inst_meth
{
    long name;
    long types;
};

struct my_objc_prot_inst_meth_list
{
    long count;
    long methods;
};

#endif
