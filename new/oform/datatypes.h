#ifndef __DATATYPES_H
#define __DATATYPES_H

typedef enum {
    OFObjCNoType,
    OFObjCCharType,
    OFObjCIntType,
    OFObjCShortType,
    OFObjCLongType,
    OFObjCLongLongType,

    OFObjCUnsignedCharType,
    OFObjCUnsignedIntType,
    OFObjCUnsignedShortType,
    OFObjCUnsignedLongType,
    OFObjCUnsignedLongLongType,

    OFObjCFloatType,
    OFObjCDoubleType,
    OFObjCVoidType,
    OFObjCStringType,
    OFObjCIDType,
    OFObjCClassType,
    OFObjCSELType,
    OFObjCArrayType,
    OFObjCStructureType,
    OFObjCUnionType,
    OFObjCBitfieldType,
    OFObjCPointerType,

    // Type Modifiers:
    OFObjCNoType,
    OFObjCConstType,
    OFObjCInType,
    OFObjCInOutType,
    OFObjCOutType,
    OFObjCByCopyType,
    OFObjCByRefType,
    OFObjCOnewayType,

    OFObjCUnknownType,
} OFObjCType;

struct OFObjCTypeNode
{
    struct OFObjCTypeNode *link;
    struct OFObjCTypeNode *subtype;
    struct OFObjCTypeNode *next;
    OFObjCType type;
    char *var_name;
    char *type_name;
};

#define array_size type_name
#define bitfield_size type_name

#define IS_ID(a) ((a)->type == OFObjCIDType && (a)->type_name == NULL)

struct OFObjCMethodTypeNode
{
    struct OFObjCMethodTypeNode *link;
    struct OFObjCMethodTypeNode *next;
    char *name;
    struct OFObjCTypeNode *type;
};

//======================================================================

struct OFObjCTypeNode *OFObjCCreateEmptyTypeNode(void);
struct OFObjCTypeNode *OFObjCCreateSimpleTypeNode(OFObjCType type);
struct OFObjCTypeNode *OFObjCCreateIDTypeNode(char *name);
struct OFObjCTypeNode *OFObjCCreateStructTypeNode(char *name, struct OFObjCTypeNode *members);
struct OFObjCTypeNode *OFObjCCreateUnionTypeNode(struct OFObjCTypeNode *members, char *type_name);
struct OFObjCTypeNode *OFObjCCreateBitfieldTypeNode(char *size);
struct OFObjCTypeNode *OFObjCCreateArrayTypeNode(char *count, struct OFObjCTypeNode *type);
struct OFObjCTypeNode *OFObjCCreatePointerTypeNode(struct OFObjCTypeNode *type);
struct OFObjCTypeNode *OFObjCCreateModifiedTypeNode(OFObjCType modifier, struct OFObjCTypeNode *type);

struct OFObjCMethodTypeNode *OFObjCCreateMethodTypeNode(struct OFObjCTypeNode *t, char *name);

struct OFObjCTypeNode *OFObjCReverseTypeNodes(struct OFObjCTypeNode *t);
struct OFObjCMethodTypeNode *OFObjCReverseMethodTypeNodes(struct OFObjCMethodTypeNode *m);

void OFObjCFreeTypeNode(struct OFObjCTypeNode *t);
void OFObjCFreeMethodTypeNode(struct OFObjCMethodTypeNode *m);

//void free_allocated_types (void);
//void free_allocated_methods (void);

#endif
