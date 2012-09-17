// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDType.h"

#import "CDTypeController.h"
#import "CDTypeName.h"
#import "CDTypeLexer.h" // For T_NAMED_OBJECT
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"

static BOOL debugMerge = NO;

@interface CDType ()
@property (nonatomic, readonly) NSString *formattedStringForSimpleType;
@end

#pragma mark -

@implementation CDType
{
    int _type; // TODO (2012-02-24): Rename to primitiveType or something
    NSArray *_protocols;
    CDType *_subtype;
    CDTypeName *_typeName;
    NSMutableArray *_members;
    NSString *_bitfieldSize;
    NSString *_arraySize;
    
    NSString *_variableName;
}

- (id)init;
{
    if ((self = [super init])) {
        _type = 0; // ??
        _protocols = nil;
        _subtype = nil;
        _typeName = nil;
        _members = nil;
        _variableName = nil;
        _bitfieldSize = nil;
        _arraySize = nil;
    }

    return self;
}

- (id)initSimpleType:(int)type;
{
    if ((self = [self init])) {
        if (type == '*') {
            _type = '^';
            _subtype = [[CDType alloc] initSimpleType:'c'];
        } else {
            _type = type;
        }
    }

    return self;
}

- (id)initIDType:(CDTypeName *)name;
{
    if ((self = [self init])) {
        if (name != nil) {
            _type = T_NAMED_OBJECT;
            _typeName = name;
        } else {
            _type = '@';
        }
    }

    return self;
}

- (id)initIDTypeWithProtocols:(NSArray *)protocols;
{
    if ((self = [self init])) {
        _type = '@';
        _protocols = protocols;
    }

    return self;
}

- (id)initStructType:(CDTypeName *)name members:(NSArray *)members;
{
    if ((self = [self init])) {
        _type = '{';
        _typeName = name;
        _members = [[NSMutableArray alloc] initWithArray:members];
    }

    return self;
}

- (id)initUnionType:(CDTypeName *)name members:(NSArray *)members;
{
    if ((self = [self init])) {
        _type = '(';
        _typeName = name;
        _members = [[NSMutableArray alloc] initWithArray:members];
    }

    return self;
}

- (id)initBitfieldType:(NSString *)bitfieldSize;
{
    if ((self = [self init])) {
        _type = 'b';
        _bitfieldSize = bitfieldSize;
    }

    return self;
}

- (id)initArrayType:(CDType *)type count:(NSString *)count;
{
    if ((self = [self init])) {
        _type = '[';
        _arraySize = count;
        _subtype = type;
    }

    return self;
}

- (id)initPointerType:(CDType *)type;
{
    if ((self = [self init])) {
        _type = '^';
        _subtype = type;
    }

    return self;
}

- (id)initModifier:(int)modifier type:(CDType *)type;
{
    if ((self = [self init])) {
        _type = modifier;
        _subtype = type;
    }

    return self;
}

#pragma mark - NSCopying

// An easy deep copy.
- (id)copyWithZone:(NSZone *)zone;
{
    NSString *str = [self typeString];
    NSParameterAssert(str != nil);
    
    CDTypeParser *parser = [[CDTypeParser alloc] initWithType:str];

    NSError *error = nil;
    CDType *copiedType = [parser parseType:&error];
    if (copiedType == nil)
        NSLog(@"Warning: Parsing type in %s failed, %@", __PRETTY_FUNCTION__, str);
    
    NSParameterAssert([str isEqualToString:copiedType.typeString]);
    
    copiedType.variableName = self.variableName;
    
    return copiedType;
}

#pragma mark -

// TODO (2009-08-26): Looks like this doesn't compare the variable name.
- (BOOL)isEqual:(id)object;
{
    if ([object isKindOfClass:[self class]]) {
        CDType *otherType = object;
        return [self.typeString isEqual:otherType.typeString];
    }
    
    return NO;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] type: %d('%c'), name: %@, subtype: %@, bitfieldSize: %@, arraySize: %@, members: %@, variableName: %@",
            NSStringFromClass([self class]), self.type, self.type, self.typeName, self.subtype, _bitfieldSize, _arraySize, self.members, self.variableName];
}

#pragma mark -

- (BOOL)isIDType;
{
    return self.type == '@' && self.typeName == nil;
}

- (BOOL)isNamedObject;
{
    return self.type == T_NAMED_OBJECT;
}

- (BOOL)isTemplateType;
{
    return self.typeName.isTemplateType;
}

- (BOOL)isModifierType;
{
    return self.type == 'j' || self.type == 'r' || self.type == 'n' || self.type == 'N' || self.type == 'o' || self.type == 'O' || self.type == 'R' || self.type == 'V';
}

- (int)typeIgnoringModifiers;
{
    if (self.isModifierType && self.subtype != nil)
        return self.subtype.typeIgnoringModifiers;

    return self.type;
}

- (NSUInteger)structureDepth;
{
    if (self.subtype != nil)
        return self.subtype.structureDepth;

    if (self.type == '{' || self.type == '(') {
        NSUInteger maxDepth = 0;

        for (CDType *member in self.members) {
            if (maxDepth < member.structureDepth)
                maxDepth = member.structureDepth;
        }

        return maxDepth + 1;
    }

    return 0;
}

- (NSString *)formattedString:(NSString *)previousName formatter:(CDTypeFormatter *)typeFormatter level:(NSUInteger)level;
{
    NSString *result, *currentName;
    NSString *baseType, *memberString;

    assert(self.variableName == nil || previousName == nil);
    if (self.variableName != nil)
        currentName = self.variableName;
    else
        currentName = previousName;

    switch (self.type) {
        case T_NAMED_OBJECT:
            assert(self.typeName != nil);
            [typeFormatter formattingDidReferenceClassName:self.typeName.name];
            if (currentName == nil)
                result = [NSString stringWithFormat:@"%@ *", self.typeName];
            else
                result = [NSString stringWithFormat:@"%@ *%@", self.typeName, currentName];
            break;
            
        case '@':
            if (currentName == nil) {
                if (_protocols == nil)
                    result = @"id";
                else
                    result = [NSString stringWithFormat:@"id <%@>", [_protocols componentsJoinedByString:@", "]];
            } else {
                if (_protocols == nil)
                    result = [NSString stringWithFormat:@"id %@", currentName];
                else
                    result = [NSString stringWithFormat:@"id <%@> %@", [_protocols componentsJoinedByString:@", "], currentName];
            }
            break;
            
        case 'b':
            if (currentName == nil) {
                // This actually compiles!
                result = [NSString stringWithFormat:@"unsigned int :%@", _bitfieldSize];
            } else
                result = [NSString stringWithFormat:@"unsigned int %@:%@", currentName, _bitfieldSize];
            break;
            
        case '[':
            if (currentName == nil)
                result = [NSString stringWithFormat:@"[%@]", _arraySize];
            else
                result = [NSString stringWithFormat:@"%@[%@]", currentName, _arraySize];
            
            result = [self.subtype formattedString:result formatter:typeFormatter level:level];
            break;
            
        case '(':
            baseType = nil;
            /*if (typeName == nil || [@"?" isEqual:[typeName description]])*/ {
                NSString *typedefName = [typeFormatter typedefNameForStruct:self level:level];
                if (typedefName != nil) {
                    baseType = typedefName;
                }
            }
            
            if (baseType == nil) {
                if (self.typeName == nil || [@"?" isEqual:[self.typeName description]])
                    baseType = @"union";
                else
                    baseType = [NSString stringWithFormat:@"union %@", self.typeName];
                
                if ((typeFormatter.shouldAutoExpand && [typeFormatter.typeController shouldExpandType:self] && [self.members count] > 0)
                    || (level == 0 && typeFormatter.shouldExpand && [self.members count] > 0))
                    memberString = [NSString stringWithFormat:@" {\n%@%@}",
                                    [self formattedStringForMembersAtLevel:level + 1 formatter:typeFormatter],
                                    [NSString spacesIndentedToLevel:typeFormatter.baseLevel + level spacesPerLevel:4]];
                else
                    memberString = @"";
                
                baseType = [baseType stringByAppendingString:memberString];
            }
            
            if (currentName == nil /*|| [currentName hasPrefix:@"?"]*/) // Not sure about this
                result = baseType;
            else
                result = [NSString stringWithFormat:@"%@ %@", baseType, currentName];
            break;
            
        case '{':
            baseType = nil;
            /*if (typeName == nil || [@"?" isEqual:[typeName description]])*/ {
                NSString *typedefName = [typeFormatter typedefNameForStruct:self level:level];
                if (typedefName != nil) {
                    baseType = typedefName;
                }
            }
            if (baseType == nil) {
                if (self.typeName == nil || [@"?" isEqual:[self.typeName description]])
                    baseType = @"struct";
                else
                    baseType = [NSString stringWithFormat:@"struct %@", self.typeName];
                
                if ((typeFormatter.shouldAutoExpand && [typeFormatter.typeController shouldExpandType:self] && [self.members count] > 0)
                    || (level == 0 && typeFormatter.shouldExpand && [self.members count] > 0))
                    memberString = [NSString stringWithFormat:@" {\n%@%@}",
                                    [self formattedStringForMembersAtLevel:level + 1 formatter:typeFormatter],
                                    [NSString spacesIndentedToLevel:typeFormatter.baseLevel + level spacesPerLevel:4]];
                else
                    memberString = @"";
                
                baseType = [baseType stringByAppendingString:memberString];
            }
            
            if (currentName == nil /*|| [currentName hasPrefix:@"?"]*/) // Not sure about this
                result = baseType;
            else
                result = [NSString stringWithFormat:@"%@ %@", baseType, currentName];
            break;
            
        case '^':
            if (currentName == nil)
                result = @"*";
            else
                result = [@"*" stringByAppendingString:currentName];
            
            if (self.subtype != nil && [self.subtype type] == '[')
                result = [NSString stringWithFormat:@"(%@)", result];
            
            result = [self.subtype formattedString:result formatter:typeFormatter level:level];
            break;
            
        case 'j':
        case 'r':
        case 'n':
        case 'N':
        case 'o':
        case 'O':
        case 'R':
        case 'V':
            if (self.subtype == nil) {
                if (currentName == nil)
                    result = [self formattedStringForSimpleType];
                else
                    result = [NSString stringWithFormat:@"%@ %@", self.formattedStringForSimpleType, currentName];
            } else
                result = [NSString stringWithFormat:@"%@ %@",
                          self.formattedStringForSimpleType, [self.subtype formattedString:currentName formatter:typeFormatter level:level]];
            break;
            
        default:
            if (currentName == nil)
                result = self.formattedStringForSimpleType;
            else
                result = [NSString stringWithFormat:@"%@ %@", self.formattedStringForSimpleType, currentName];
            break;
    }
    
    return result;
}

- (NSString *)formattedStringForMembersAtLevel:(NSUInteger)level formatter:(CDTypeFormatter *)typeFormatter;
{
    NSParameterAssert(self.type == '{' || self.type == '(');
    NSMutableString *str = [NSMutableString string];

    for (CDType *member in self.members) {
        [str appendString:[NSString spacesIndentedToLevel:typeFormatter.baseLevel + level spacesPerLevel:4]];
        [str appendString:[member formattedString:nil
                                  formatter:typeFormatter
                                  level:level]];
        [str appendString:@";\n"];
    }

    return str;
}

- (NSString *)formattedStringForSimpleType;
{
    // Ugly but simple:
    switch (self.type) {
        case 'c': return @"char";
        case 'i': return @"int";
        case 's': return @"short";
        case 'l': return @"long";
        case 'q': return @"long long";
        case 'C': return @"unsigned char";
        case 'I': return @"unsigned int";
        case 'S': return @"unsigned short";
        case 'L': return @"unsigned long";
        case 'Q': return @"unsigned long long";
        case 'f': return @"float";
        case 'd': return @"double";
        case 'D': return @"long double";
        case 'B': return @"_Bool"; /* C99 _Bool or C++ bool */
        case 'v': return @"void";
        case '*': return @"STR";
        case '#': return @"Class";
        case ':': return @"SEL";
        case '%': return @"NXAtom";
        case '?': return @"void";
            //case '?': return @"UNKNOWN"; // For easier regression testing.
        case 'j': return @"_Complex";
        case 'r': return @"const";
        case 'n': return @"in";
        case 'N': return @"inout";
        case 'o': return @"out";
        case 'O': return @"bycopy";
        case 'R': return @"byref";
        case 'V': return @"oneway";
        default:
            break;
    }

    return nil;
}

- (NSString *)typeString;
{
    return [self _typeStringWithVariableNamesToLevel:1e6 showObjectTypes:YES];
}

- (NSString *)bareTypeString;
{
    return [self _typeStringWithVariableNamesToLevel:0 showObjectTypes:YES];
}

- (NSString *)reallyBareTypeString;
{
    return [self _typeStringWithVariableNamesToLevel:0 showObjectTypes:NO];
}

- (NSString *)keyTypeString;
{
    // use variable names at top level
    return [self _typeStringWithVariableNamesToLevel:1 showObjectTypes:YES];
}

- (NSString *)_typeStringWithVariableNamesToLevel:(NSUInteger)level showObjectTypes:(BOOL)shouldShowObjectTypes;
{
    NSString *result;
    
    switch (self.type) {
        case T_NAMED_OBJECT:
            assert(self.typeName != nil);
            if (shouldShowObjectTypes)
                result = [NSString stringWithFormat:@"@\"%@\"", self.typeName];
            else
                result = @"@";
            break;
            
        case '@':
            result = @"@";
            break;
            
        case 'b':
            result = [NSString stringWithFormat:@"b%@", _bitfieldSize];
            break;
            
        case '[':
            result = [NSString stringWithFormat:@"[%@%@]", _arraySize, [self.subtype _typeStringWithVariableNamesToLevel:level showObjectTypes:shouldShowObjectTypes]];
            break;
            
        case '(':
            if (self.typeName == nil) {
                return [NSString stringWithFormat:@"(%@)", [self _typeStringForMembersWithVariableNamesToLevel:level showObjectTypes:shouldShowObjectTypes]];
            } else if ([self.members count] == 0) {
                return [NSString stringWithFormat:@"(%@)", self.typeName];
            } else {
                return [NSString stringWithFormat:@"(%@=%@)", self.typeName, [self _typeStringForMembersWithVariableNamesToLevel:level showObjectTypes:shouldShowObjectTypes]];
            }
            
        case '{':
            if (self.typeName == nil) {
                return [NSString stringWithFormat:@"{%@}", [self _typeStringForMembersWithVariableNamesToLevel:level showObjectTypes:shouldShowObjectTypes]];
            } else if ([self.members count] == 0) {
                return [NSString stringWithFormat:@"{%@}", self.typeName];
            } else {
                return [NSString stringWithFormat:@"{%@=%@}", self.typeName, [self _typeStringForMembersWithVariableNamesToLevel:level showObjectTypes:shouldShowObjectTypes]];
            }
            
        case '^':
            result = [NSString stringWithFormat:@"^%@", [self.subtype _typeStringWithVariableNamesToLevel:level showObjectTypes:shouldShowObjectTypes]];
            break;
            
        case 'j':
        case 'r':
        case 'n':
        case 'N':
        case 'o':
        case 'O':
        case 'R':
        case 'V':
            result = [NSString stringWithFormat:@"%c%@", self.type, [self.subtype _typeStringWithVariableNamesToLevel:level showObjectTypes:shouldShowObjectTypes]];
            break;
            
        default:
            result = [NSString stringWithFormat:@"%c", self.type];
            break;
    }

    return result;
}

- (NSString *)_typeStringForMembersWithVariableNamesToLevel:(NSInteger)level showObjectTypes:(BOOL)shouldShowObjectTypes;
{
    NSParameterAssert(self.type == '{' || self.type == '(');
    NSMutableString *str = [NSMutableString string];

    for (CDType *member in self.members) {
        if (member.variableName != nil && level > 0)
            [str appendFormat:@"\"%@\"", member.variableName];
        [str appendString:[member _typeStringWithVariableNamesToLevel:level - 1 showObjectTypes:shouldShowObjectTypes]];
    }

    return str;
}

- (BOOL)canMergeWithType:(CDType *)otherType;
{
    if (self.isIDType && otherType.isNamedObject)
        return YES;

    if (self.isNamedObject && otherType.isIDType) {
        return YES;
    }

    if (self.type != otherType.type) {
        if (debugMerge) {
            NSLog(@"--------------------");
            NSLog(@"this: %@", self.typeString);
            NSLog(@"other: %@", otherType.typeString);
            NSLog(@"self isIDType? %u", self.isIDType);
            NSLog(@"self isNamedObject? %u", self.isNamedObject);
            NSLog(@"other isIDType? %u", otherType.isIDType);
            NSLog(@"other isNamedObject? %u", otherType.isNamedObject);
        }
        if (debugMerge) NSLog(@"%s, Can't merge because of type... %@ vs %@", __cmd, self.typeString, otherType.typeString);
        return NO;
    }

    if (self.subtype != nil && [self.subtype canMergeWithType:otherType.subtype] == NO) {
        if (debugMerge) NSLog(@"%s, Can't merge subtype", __cmd);
        return NO;
    }

    if (self.subtype == nil && otherType.subtype != nil) {
        if (debugMerge) NSLog(@"%s, This subtype is nil, other isn't.", __cmd);
        return NO;
    }

    NSArray *otherMembers = otherType.members;
    NSUInteger count = [self.members count];
    NSUInteger otherCount = [otherMembers count];

    //NSLog(@"members: %p", members);
    //NSLog(@"otherMembers: %p", otherMembers);
    //NSLog(@"%s, count: %u, otherCount: %u", __cmd, count, otherCount);

    if (count != 0 && otherCount == 0) {
        if (debugMerge) NSLog(@"%s, count != 0 && otherCount is 0", __cmd);
        return NO;
    }

    if (count != 0 && count != otherCount) {
        if (debugMerge) NSLog(@"%s, count != 0 && count != otherCount", __cmd);
        return NO;
    }

    // count == 0 is ok: we just have a name in that case.
    if (count == otherCount) {
        for (NSUInteger index = 0; index < count; index++) { // Oooh
            CDType *thisMember = self.members[index];
            CDType *otherMember = otherMembers[index];

            CDTypeName *thisTypeName = thisMember.typeName;
            CDTypeName *otherTypeName = otherMember.typeName;
            NSString *thisVariableName = thisMember.variableName;
            NSString *otherVariableName = otherMember.variableName;

            // It seems to be okay if one of them didn't have a name
            if (thisTypeName != nil && otherTypeName != nil && [thisTypeName isEqual:otherTypeName] == NO) {
                if (debugMerge) NSLog(@"%s, typeName mismatch on member %lu", __cmd, index);
                return NO;
            }

            if (thisVariableName != nil && otherVariableName != nil && [thisVariableName isEqual:otherVariableName] == NO) {
                if (debugMerge) NSLog(@"%s, variableName mismatch on member %lu", __cmd, index);
                return NO;
            }

            if ([thisMember canMergeWithType:otherMember] == NO) {
                if (debugMerge) NSLog(@"%s, Can't merge member %lu", __cmd, index);
                return NO;
            }
        }
    }

    return YES;
}

// Merge struct/union member names.  Should check using -canMergeWithType: first.
// Recursively merges, not just the top level.
- (void)mergeWithType:(CDType *)otherType;
{
    NSString *before = self.typeString;
    [self _recursivelyMergeWithType:otherType];
    NSString *after = self.typeString;
    if (debugMerge) {
        NSLog(@"----------------------------------------");
        NSLog(@"%s", __cmd);
        NSLog(@"before: %@", before);
        NSLog(@" after: %@", after);
        NSLog(@"----------------------------------------");
    }
}

- (void)_recursivelyMergeWithType:(CDType *)otherType;
{
    if (self.isIDType && otherType.isNamedObject) {
        //NSLog(@"thisType: %@", [self typeString]);
        //NSLog(@"otherType: %@", [otherType typeString]);
        _type = T_NAMED_OBJECT;
        _typeName = [otherType.typeName copy];
        return;
    }

    if (self.isNamedObject && otherType.isIDType) {
        return;
    }

    if (self.type != otherType.type) {
        NSLog(@"Warning: Trying to merge different types in %s", __cmd);
        return;
    }

    [self.subtype _recursivelyMergeWithType:otherType.subtype];

    NSArray *otherMembers = otherType.members;
    NSUInteger count = [self.members count];
    NSUInteger otherCount = [otherMembers count];

    // The counts can be zero when we register structures that just have a name.  That happened while I was working on the
    // structure registration.
    if (otherCount == 0) {
        return;
    } else if (count == 0 && otherCount != 0) {
        NSParameterAssert(self.members != nil);
        [_members removeAllObjects];
        [_members addObjectsFromArray:otherMembers];
        //[self setMembers:otherMembers];
    } else if (count != otherCount) {
        // Not so bad after all.  Even kind of common.  Consider _flags.
        NSLog(@"Warning: Types have different number of members.  This is bad. (%lu vs %lu)", count, otherCount);
        NSLog(@"%@ vs %@", self.typeString, otherType.typeString);
        return;
    }

    //NSLog(@"****************************************");
    for (NSUInteger index = 0; index < count; index++) {
        CDType *thisMember = self.members[index];
        CDType *otherMember = otherMembers[index];

        CDTypeName *thisTypeName = thisMember.typeName;
        CDTypeName *otherTypeName = otherMember.typeName;
        NSString *thisVariableName = thisMember.variableName;
        NSString *otherVariableName = otherMember.variableName;
        //NSLog(@"%d: type: %@ vs %@", index, thisTypeName, otherTypeName);
        //NSLog(@"%d: vari: %@ vs %@", index, thisVariableName, otherVariableName);

        if ((thisTypeName == nil && otherTypeName != nil) || (thisTypeName != nil && otherTypeName == nil)) {
            ; // It seems to be okay if one of them didn't have a name
            //NSLog(@"Warning: (1) type names don't match, %@ vs %@", thisTypeName, otherTypeName);
        } else if (thisTypeName != nil && [thisTypeName isEqual:otherTypeName] == NO) {
            NSLog(@"Warning: (2) type names don't match:\n\t%@ vs \n\t%@.", thisTypeName, otherTypeName);
            // In this case, we should skip the merge.
        }

        if (otherVariableName != nil) {
            if (thisVariableName == nil)
                thisMember.variableName = otherVariableName;
            else if ([thisVariableName isEqual:otherVariableName] == NO)
                NSLog(@"Warning: Different variable names for same member...");
        }

        [thisMember _recursivelyMergeWithType:otherMember];
    }
}

- (NSArray *)memberVariableNames;
{
    NSMutableArray *names = [[NSMutableArray alloc] init];
    [self.members enumerateObjectsUsingBlock:^(CDType *memberType, NSUInteger index, BOOL *stop){
        if (memberType.variableName != nil)
            [names addObject:memberType.variableName];
    }];
    
    return [names copy];
}

- (void)generateMemberNames;
{
    if (self.type == '{' || self.type == '(') {
        NSSet *usedNames = [[NSSet alloc] initWithArray:self.memberVariableNames];

        NSUInteger number = 1;
        for (CDType *member in self.members) {
            [member generateMemberNames];

            // Bitfields don't need a name.
            if (member.variableName == nil && member.type != 'b') {
                NSString *name;
                do {
                    name = [NSString stringWithFormat:@"_field%lu", number++];
                } while ([usedNames containsObject:name]);
                member.variableName = name;
            }
        }
    }

    [self.subtype generateMemberNames];
}

#pragma mark - Phase 0

- (void)phase:(NSUInteger)phase registerTypesWithObject:(CDTypeController *)typeController usedInMethod:(BOOL)isUsedInMethod;
{
    if (phase == 0) {
        [self phase0RegisterStructuresWithObject:typeController usedInMethod:isUsedInMethod];
    }
}

// Just top level structures
- (void)phase0RegisterStructuresWithObject:(CDTypeController *)typeController usedInMethod:(BOOL)isUsedInMethod;
{
    // ^{ComponentInstanceRecord=}
    if (self.subtype != nil)
        [self.subtype phase0RegisterStructuresWithObject:typeController usedInMethod:isUsedInMethod];

    if ((self.type == '{' || self.type == '(') && [self.members count] > 0) {
        [typeController phase0RegisterStructure:self usedInMethod:isUsedInMethod];
    }
}

- (void)phase0RecursivelyFixStructureNames:(BOOL)flag;
{
    [self.subtype phase0RecursivelyFixStructureNames:flag];

    if ([self.typeName.name hasPrefix:@"$"]) {
        if (flag) NSLog(@"%s, changing type name %@ to ?", __cmd, self.typeName.name);
        self.typeName.name = @"?";
    }

    for (CDType *member in self.members)
        [member phase0RecursivelyFixStructureNames:flag];
}

#pragma mark - Phase 1

// Recursively go through type, registering structs/unions.
- (void)phase1RegisterStructuresWithObject:(CDTypeController *)typeController;
{
    // ^{ComponentInstanceRecord=}
    if (self.subtype != nil)
        [self.subtype phase1RegisterStructuresWithObject:typeController];

    if ((self.type == '{' || self.type == '(') && [self.members count] > 0) {
        [typeController phase1RegisterStructure:self];
        for (CDType *member in self.members)
            [member phase1RegisterStructuresWithObject:typeController];
    }
}

#pragma mark - Phase 2

// This wraps the recursive method, optionally logging if anything changed.
- (void)phase2MergeWithTypeController:(CDTypeController *)typeController debug:(BOOL)phase2Debug;
{
    NSString *before = self.typeString;
    [self _phase2MergeWithTypeController:typeController debug:phase2Debug];
    NSString *after = self.typeString;
    if (phase2Debug && [before isEqualToString:after] == NO) {
        NSLog(@"----------------------------------------");
        NSLog(@"%s, merge changed type", __cmd);
        NSLog(@"before: %@", before);
        NSLog(@" after: %@", after);
    }
}

// Recursive, bottom-up
- (void)_phase2MergeWithTypeController:(CDTypeController *)typeController debug:(BOOL)phase2Debug;
{
    [self.subtype _phase2MergeWithTypeController:typeController debug:phase2Debug];

    for (CDType *member in self.members)
        [member _phase2MergeWithTypeController:typeController debug:phase2Debug];

    if ((self.type == '{' || self.type == '(') && [self.members count] > 0) {
        CDType *phase2Type = [typeController phase2ReplacementForType:self];
        if (phase2Type != nil) {
            // >0 members so we don't try replacing things like... {_xmlNode=^{_xmlNode}}
            if ([self.members count] > 0 && [self canMergeWithType:phase2Type]) {
                [self mergeWithType:phase2Type];
            } else {
                if (phase2Debug) {
                    NSLog(@"Found phase2 type, but can't merge with it.");
                    NSLog(@"this: %@", [self typeString]);
                    NSLog(@"that: %@", [phase2Type typeString]);
                }
            }
        }
    }
}

#pragma mark - Phase 3

- (void)phase3RegisterWithTypeController:(CDTypeController *)typeController;
{
    [self.subtype phase3RegisterWithTypeController:typeController];

    if (self.type == '{' || self.type == '(') {
        [typeController phase3RegisterStructure:self /*count:1 usedInMethod:NO*/];
    }
}

- (void)phase3RegisterMembersWithTypeController:(CDTypeController *)typeController;
{
    //NSLog(@" > %s %@", __cmd, [self typeString]);
    for (CDType *member in self.members) {
        [member phase3RegisterWithTypeController:typeController];
    }
    //NSLog(@"<  %s", __cmd);
}

// Bottom-up
- (void)phase3MergeWithTypeController:(CDTypeController *)typeController;
{
    [self.subtype phase3MergeWithTypeController:typeController];

    for (CDType *member in self.members)
        [member phase3MergeWithTypeController:typeController];

    if ((self.type == '{' || self.type == '(') && [self.members count] > 0) {
        CDType *phase3Type = [typeController phase3ReplacementForType:self];
        if (phase3Type != nil) {
            // >0 members so we don't try replacing things like... {_xmlNode=^{_xmlNode}}
            if ([self.members count] > 0 && [self canMergeWithType:phase3Type]) {
                [self mergeWithType:phase3Type];
            } else {
#if 0
                // This can happen in AU Lab, that struct has no members...
                NSLog(@"Found phase3 type, but can't merge with it.");
                NSLog(@"this: %@", self.typeString);
                NSLog(@"that: %@", phase3Type.typeString);
#endif
            }
        }
    }
}

@end
