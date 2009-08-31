struct cd_objc2_list_header {
    uint32_t entsize;
    uint32_t count;
};

struct cd_objc2_image_info {
    uint32_t version;
    uint32_t flags;
};

//
// 32-bit
//

struct cd_objc2_class_32 {
    uint32_t isa;
    uint32_t superclass;
    uint32_t cache;
    uint32_t vtable;
    uint32_t data; // points to class_ro_t
    uint32_t reserved1;
    uint32_t reserved2;
    uint32_t reserved3;
};

struct cd_objc2_class_ro_t_32 {
    uint32_t flags;
    uint32_t instanceStart;
    uint32_t instanceSize;
    uint32_t reserved;
    uint32_t ivarLayout;
    uint32_t name;
    uint32_t baseMethods;
    uint32_t baseProtocols;
    uint32_t ivars;
    uint32_t weakIvarLayout;
    uint32_t baseProperties;
};

struct cd_objc2_method_32 {
    uint32_t name;
    uint32_t types;
    uint32_t imp;
};

struct cd_objc2_ivar_32 {
    uint32_t offset;
    uint32_t name;
    uint32_t type;
    uint32_t alignment;
    uint32_t size;
};

struct cd_objc2_property_32 {
    uint32_t name;
    uint32_t attributes;
};

struct cd_objc2_protocol_32 {
    uint32_t isa;
    uint32_t name;
    uint32_t protocols;
    uint32_t instanceMethods;
    uint32_t classMethods;
    uint32_t optionalInstanceMethods;
    uint32_t optionalClassMethods;
    uint32_t instanceProperties; // So far, always 0
};

struct cd_objc2_category_32 {
    uint32_t name;
    uint32_t class;
    uint32_t instanceMethods;
    uint32_t classMethods;
    uint32_t protocols;
    uint32_t instanceProperties;
    uint32_t v7;
    uint32_t v8;
};

//
// 64-bit
//

struct cd_objc2_class_64 {
    uint64_t isa;
    uint64_t superclass;
    uint64_t cache;
    uint64_t vtable;
    uint64_t data; // points to class_ro_t
    uint64_t reserved1;
    uint64_t reserved2;
    uint64_t reserved3;
};

struct cd_objc2_class_ro_t_64 {
    uint32_t flags;
    uint32_t instanceStart;
    uint32_t instanceSize;
    uint32_t reserved;
    uint64_t ivarLayout;
    uint64_t name;
    uint64_t baseMethods;
    uint64_t baseProtocols;
    uint64_t ivars;
    uint64_t weakIvarLayout;
    uint64_t baseProperties;
};

struct cd_objc2_method_64 {
    uint64_t name;
    uint64_t types;
    uint64_t imp;
};

struct cd_objc2_ivar_64 {
    uint64_t offset;
    uint64_t name;
    uint64_t type;
    uint32_t alignment;
    uint32_t size;
};

struct cd_objc2_property_64 {
    uint64_t name;
    uint64_t attributes;
};

struct cd_objc2_protocol_64 {
    uint64_t isa;
    uint64_t name;
    uint64_t protocols;
    uint64_t instanceMethods;
    uint64_t classMethods;
    uint64_t optionalInstanceMethods;
    uint64_t optionalClassMethods;
    uint64_t instanceProperties; // So far, always 0
};

struct cd_objc2_category_64 {
    uint64_t name;
    uint64_t class;
    uint64_t instanceMethods;
    uint64_t classMethods;
    uint64_t protocols;
    uint64_t instanceProperties;
    uint64_t v7;
    uint64_t v8;
};
