
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "datatypes.h"

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

struct OFObjCTypeNode *allocated_types = NULL;
struct OFObjCMethodTypeNode *allocated_methods = NULL;

//======================================================================
// Type creation functions
//======================================================================

struct OFObjCTypeNode *OFObjCCreateEmptyTypeNode(void);
{
    struct OFObjCTypeNode *tmp = malloc (sizeof (struct OFObjCTypeNode));

    assert (tmp != NULL);

    tmp->link = allocated_types;
    allocated_types = tmp;

    tmp->subtype = NULL;
    tmp->next = NULL;
    tmp->type = OFObjCNoType;
    tmp->var_name = NULL;
    tmp->type_name = NULL;

    return tmp;
}

struct OFObjCTypeNode *OFObjCCreateSimpleTypeNode(OFObjCType type);
{
    struct OFObjCTypeNode *t = OFObjCCreateEmptyTypeNode();

    if (type == OFObjCStringType)
    {
        t->type = OFObjCPointerType;
        t->subtype = OFObjCCreateEmptyTypeNode(OFObjCCharType);
    }
    else
    {
        t->type = type;
    }

    return t;
}

struct OFObjCTypeNode *OFObjCCreateIDTypeNode(char *name);
{
    struct OFObjCTypeNode *t = OFObjCCreateEmptyTypeNode();

    t->type_name = name;

    if (name != NULL)
    {
        t->type = T_NAMED_OBJECT;
        return OFObjCCreatePointerTypeNode(t);
    }
    else
    {
        t->type = OFObjCIDType;
    }

    return t;
}

struct OFObjCTypeNode *OFObjCCreateStructTypeNode(char *name, struct OFObjCTypeNode *members);
{
    struct OFObjCTypeNode *t = OFObjCCreateEmptyTypeNode();

    t->type = OFObjCStructureType;
    t->type_name = name;
    t->subtype = members;

    return t;
}

struct OFObjCTypeNode *OFObjCCreateUnionTypeNode(struct OFObjCTypeNode *members, char *type_name);
{
    struct OFObjCTypeNode *t = OFObjCCreateEmptyTypeNode();

    t->type = OFObjCUnionType;
    t->subtype = members;
    t->type_name = type_name;

    return t;
}

struct OFObjCTypeNode *OFObjCCreateBitfieldTypeNode(char *size);
{
    struct OFObjCTypeNode *t = OFObjCCreateEmptyTypeNode();

    t->type = OFObjCBitfieldType;
    t->bitfield_size = size;

    return t;
}

struct OFObjCTypeNode *OFObjCCreateArrayTypeNode(char *count, struct OFObjCTypeNode *type);
{
    struct OFObjCTypeNode *t = OFObjCCreateEmptyTypeNode();

    t->type = OFObjCArrayType;
    t->array_size = count;
    t->subtype = type;

    return t;
}

struct OFObjCTypeNode *OFObjCCreatePointerTypeNode(struct OFObjCTypeNode *type);
{
    struct OFObjCTypeNode *t = OFObjCCreateEmptyTypeNode();

    t->type = OFObjCPointerType;
    t->subtype = type;

    return t;
}

struct OFObjCTypeNode *OFObjCCreateModifiedTypeNode(OFObjCType modifier, struct OFObjCTypeNode *type);
{
    struct OFObjCTypeNode *t = OFObjCCreateEmptyTypeNode();

    t->type = modifier;
    t->subtype = type;

    return t;
}

//======================================================================
// Method creation functions
//======================================================================

struct OFObjCMethodTypeNode *create_OFObjCMethodTypeNode (struct OFObjCTypeNode *t, char *name)
{
    struct OFObjCMethodTypeNode *tmp = malloc (sizeof (struct OFObjCMethodTypeNode));

    assert (tmp != NULL);

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

struct OFObjCTypeNode *reverse_types (struct OFObjCTypeNode *t)
{
    struct OFObjCTypeNode *head = NULL;
    struct OFObjCTypeNode *tmp;

    while (t != NULL)
    {
        tmp = t;
        t = t->next;
        tmp->next = head;
        head = tmp;
    }

    return head;
}

struct OFObjCMethodTypeNode *reverse_OFObjCMethodTypeNodes (struct OFObjCMethodTypeNode *m)
{
    struct OFObjCMethodTypeNode *head = NULL;
    struct OFObjCMethodTypeNode *tmp;

    while (m != NULL)
    {
        tmp = m;
        m = m->next;
        tmp->next = head;
        head = tmp;
    }

    return head;
}

//======================================================================

void free_objc_type (struct OFObjCTypeNode *t)
{
    struct OFObjCTypeNode *tmp;

    while (t != NULL)
    {
        tmp = t;
        t = t->next;

        if (tmp->var_name != NULL)
            free (tmp->var_name);
        if (tmp->type_name != NULL)
            free (tmp->type_name);
        if (tmp->subtype != NULL)
            free_objc_type (tmp->subtype);
    }
}

void free_OFObjCMethodTypeNode (struct OFObjCMethodTypeNode *m)
{
    struct OFObjCMethodTypeNode *tmp;

    while (m != NULL)
    {
        tmp = m;
        m = m->next;

        if (tmp->name != NULL)
            free (tmp->name);
        free_objc_type (tmp->type);
    }
}

//======================================================================
#if 0
void free_allocated_types (void)
{
    struct OFObjCTypeNode *tmp;

    while (allocated_types != NULL)
    {
        tmp = allocated_types;
        allocated_types = allocated_types->link;

        if (tmp->var_name != NULL)
            free (tmp->var_name);
        if (tmp->type_name != NULL)
            free (tmp->type_name);
    }
}

void free_allocated_methods (void)
{
    struct OFObjCMethodTypeNode *tmp;

    while (allocated_methods != NULL)
    {
        tmp = allocated_methods;
        allocated_methods = allocated_methods->link;

        if (tmp->name != NULL)
            free (tmp->name);
    }
}
#endif
