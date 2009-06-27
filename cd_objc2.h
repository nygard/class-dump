struct cd_objc2_list_header {
    uint32_t entsize;
    uint32_t count;
};

struct cd_objc2_image_info {
    uint32_t version;
    uint32_t flags;
};

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
    uint64_t v5;
    uint64_t v6;
    uint64_t v7;
    uint64_t v8;
};
