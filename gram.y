%{

//
// $Id: gram.y,v 1.11 2003/09/06 21:17:56 nygard Exp $
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

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "datatypes.h"

extern int ident_state;
extern char yytext[];

struct method_type *rtype = NULL;
int parsing_ivar = 0;

//----------------------------------------------------------------------

int yylex(void);
int yyerror(char *s);

%}

%union {
    int u_int;
    char *u_str;
    struct my_objc_type *u_type;
    struct method_type *u_meth;
};

%type <u_int> start
%type <u_meth> method_type_list method_type

%type <u_type> type
%type <u_int> modifier
%type <u_type> unmodified_type
%type <u_int> simple_type
%type <u_type> id_type
%type <u_type> structure_type
%type <u_type> optional_format
%type <u_type> taglist
%type <u_type> tag
%type <u_str> quoted_name
%type <u_int> quoted_name_prefix
%type <u_type> union_type
%type <u_type> union_types
%type <u_type> array_type
%type <u_str> identifier type_name
%type <u_str> number


%type <u_int> 'c' 'i' 's' 'l' 'q'
%type <u_int> 'C' 'I' 'S' 'L' 'Q'
%type <u_int> 'f' 'd' 'B' 'v' '*'
%type <u_int> '#' ':' '%' 'r' 'n'
%type <u_int> 'N' 'o' 'O' 'R' 'V'

%type <u_int> '^' 'b'

%token <u_str> TK_NUMBER
%token <u_str> TK_IDENTIFIER

%token T_NAMED_OBJECT

%expect 1

%%

start:
	type
		{
			rtype = create_method_type($1, NULL);
			$$ = 0;
		}
	| method_type_list
		{
			rtype = reverse_method_types($1);
			$$ = 0;
		}
	;

method_type_list:
	method_type
	| method_type_list method_type
		{
			$2->next = $1;
			$$ = $2;
		}
	;

method_type:
	type number
		{
			$$ = create_method_type($1, $2);
		}
	;

type:	unmodified_type
	| modifier type
		{
			$$ = create_modified_type($1, $2);
		}
	;

modifier:
	'r' { $$ = 'r'; }
	| 'n' { $$ = 'n'; }
	| 'N' { $$ = 'N'; }
	| 'o' { $$ = 'o'; }
	| 'O' { $$ = 'O'; }
	| 'R' { $$ = 'R'; }
	| 'V' { $$ = 'V'; }
	;

unmodified_type:
	simple_type
		{
			$$ = create_simple_type($1);
		}
	| id_type
	| '^' type
		{
			$$ = create_pointer_type($2);
		}
	| 'b' number
		{
			$$ = create_bitfield_type($2);
		}
	| structure_type
	| union_type
	| array_type
	;

simple_type:
	'c' { $$ = 'c'; }
	| 'i' { $$ = 'i'; }
	| 's' { $$ = 's'; }
	| 'l' { $$ = 'l'; }
	| 'q' { $$ = 'q'; }
	| 'C' { $$ = 'C'; }
	| 'I' { $$ = 'I'; }
	| 'S' { $$ = 'S'; }
	| 'L' { $$ = 'L'; }
	| 'Q' { $$ = 'Q'; }
	| 'f' { $$ = 'f'; }
	| 'd' { $$ = 'd'; }
	| 'B' { $$ = 'B'; }
	| 'v' { $$ = 'v'; }
	| '*' { $$ = '*'; }
	| '#' { $$ = '#'; }
	| ':' { $$ = ':'; }
	| '%' { $$ = '%'; }
	| '?' { $$ = '?'; }
	;

/* This gives the shift/reduce error... */

id_type:
	'@'
		{
			$$ = create_id_type(NULL);
		}
	| '@' quoted_name
		{
			$$ = create_id_type($2);
		}
	;

structure_type:
	'{' { ident_state = 1; } type_name optional_format '}'
		{
			$$ = create_struct_type($3, $4);
		}
	;

optional_format:
	/* empty */
		{
			$$ = NULL;
		}
	| '=' taglist
		{
			$$ = reverse_types($2);
		}
	;

taglist:
	/* empty */
		{
			$$ = NULL;
		}
	| taglist tag
		{
			$2->next = $1;
			$$ = $2;
		}
	;

tag:
	quoted_name type
		{
			$2->var_name = $1;
			$$ = $2;
		}
	| type
		{
			$1->var_name = strdup("___");
			$$ = $1;
		}
	;

quoted_name:
	quoted_name_prefix identifier '"'
		{
			$$ = $2;
		}
	| quoted_name_prefix '"'
		{
			$$ = strdup("");
		}
	;

quoted_name_prefix:
	'"' { ident_state = 1; }
	;

union_type:
	union_type_prefix union_types ')'
		{
			$$ = create_union_type(reverse_types($2), NULL);
		}
	| union_type_prefix identifier optional_format ')'
		{
			$$ = create_union_type($3, $2);
		}
	;

union_type_prefix:
	'('
		{
			/*
			 * Great - for a union, an instance variable has a name, and no type,
			 *         but a method has the types, and no name!
			 */
			/* if (parsing_ivar == 1) */ /* Methods can have names now... -CEL */
				ident_state = 1;
		}
	;

union_types:
	/* empty */
		{
			$$ = NULL;
		}
	| union_types type
		{
			$2->var_name = strdup("___");
			$2->next = $1;
			$$ = $2;
		}
	;

array_type:
	'[' number type ']'
		{
			$$ = create_array_type($2, $3);
		}
	;

identifier:
	TK_IDENTIFIER
		{
			$$ = strdup(yytext);
		}
	;

type_name:
        identifier optional_template_type
        	{
			$$ = $1;
		}
        ;

optional_template_type:
	/* empty */
	| '<' { ident_state = 1; } identifier optional_identifier_list_suffix '>'
	;

/* I know, it's not good to be right recursive... */

optional_identifier_list_suffix:
	/* empty */
	| ',' { ident_state = 1; } identifier optional_identifier_list_suffix
	;

number:
	TK_NUMBER
		{
			$$ = strdup(yytext);
		}
	;

%%

extern int yy_scan_string(const char *);
extern int yyparse(void);

int yyerror(char *s)
{
	fprintf(stderr, "%s\n", s);
	return 0;
}

int parse_ivar_type(void)
{
	parsing_ivar = 1;
	return yyparse();
}

int parse_method_type(void)
{
	parsing_ivar = 0;
	return yyparse();
}

void format_type(const char *type, const char *name, int level)
{
	int parse_flag;
        extern int expand_structures_flag;

	rtype = NULL;
	yy_scan_string(type);
	parse_flag = parse_ivar_type();

	if (parse_flag == 0)
	{
		if (name != NULL)
			rtype->type->var_name = strdup(name);
                indent_to_level(level);
		print_type(rtype->type, expand_structures_flag, level);
		printf(";");

		rtype = NULL;
	}
	else
        {
		printf("// Error! format_type('%s', '%s')\n", type, name);
                printf("\n\n");
        }

	free_allocated_methods();
	free_allocated_types();
}

void format_method(char method_type, const char *name, const char *types)
{
	int parse_flag;

	if (name == NULL)
	{
		printf("// %c (method name not found in OBJC segments), args: %s", method_type, types);
		return;
	}

        if (*name == '\0' || *types == '\0')
        {
		printf("// Error! format_method(%c, '%s', '%s')", method_type, name, types);
		return;
        }

	rtype = NULL;
	yy_scan_string(types);
	parse_flag = parse_method_type();

	if (parse_flag == 0)
	{
		print_method(method_type, name, rtype);
		rtype = NULL;
	}
	else
        {
		extern const char *scanner_ptr;

		printf("// Error! format_method(%c, %s, %s )\n", method_type, name, types);
                printf("// at %s\n", scanner_ptr);
                printf("\n\n");
        }

	free_allocated_methods();
	free_allocated_types();
}
