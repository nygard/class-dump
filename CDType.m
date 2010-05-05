// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDType.h"

#import "NSArray-Extensions.h"
#import "NSString-Extensions.h"
#import "CDSymbolReferences.h"
#import "CDTypeController.h"
#import "CDTypeName.h"
#import "CDTypeLexer.h" // For T_NAMED_OBJECT
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"
#import "NSError-CDExtensions.h"

static BOOL debugMerge = NO;

@implementation CDType

- (id)init;
{
    if ([super init] == nil)
        return nil;

    type = 0; // ??
    protocols = nil;
    subtype = nil;
    typeName = nil;
    members = nil;
    variableName = nil;
    bitfieldSize = nil;
    arraySize = nil;

    return self;
}

- (id)initSimpleType:(int)aTypeCode;
{
    if ([self init] == nil)
        return nil;

    if (aTypeCode == '*') {
        type = '^';
        subtype = [[CDType alloc] initSimpleType:'c'];
    } else {
        type = aTypeCode;
    }

    return self;
}

- (id)initIDType:(CDTypeName *)aName;
{
    if ([self init] == nil)
        return nil;

    if (aName != nil) {
        type = T_NAMED_OBJECT;
        typeName = [aName retain];
    } else {
        type = '@';
    }

    return self;
}

- (id)initIDTypeWithProtocols:(NSArray *)someProtocols;
{
    if ([self init] == nil)
        return nil;

    type = '@';
    protocols = [someProtocols retain];

    return self;
}

- (id)initStructType:(CDTypeName *)aName members:(NSArray *)someMembers;
{
    if ([self init] == nil)
        return nil;

    type = '{';
    typeName = [aName retain];
    members = [[NSMutableArray alloc] initWithArray:someMembers];

    return self;
}

- (id)initUnionType:(CDTypeName *)aName members:(NSArray *)someMembers;
{
    if ([self init] == nil)
        return nil;

    type = '(';
    typeName = [aName retain];
    members = [[NSMutableArray alloc] initWithArray:someMembers];

    return self;
}

- (id)initBitfieldType:(NSString *)aBitfieldSize;
{
    if ([self init] == nil)
        return nil;

    type = 'b';
    bitfieldSize = [aBitfieldSize retain];

    return self;
}

- (id)initArrayType:(CDType *)aType count:(NSString *)aCount;
{
    if ([self init] == nil)
        return nil;

    type = '[';
    arraySize = [aCount retain];
    subtype = [aType retain];

    return self;
}

- (id)initPointerType:(CDType *)aType;
{
    if ([self init] == nil)
        return nil;

    type = '^';
    subtype = [aType retain];

    return self;
}

- (id)initModifier:(int)aModifier type:(CDType *)aType;
{
    if ([self init] == nil)
        return nil;

    type = aModifier;
    subtype = [aType retain];

    return self;
}

- (void)dealloc;
{
    [protocols release];
    [subtype release];
    [typeName release];
    [members release];
    [variableName release];
    [bitfieldSize release];
    [arraySize release];

    [super dealloc];
}

@synthesize variableName;

- (int)type;
{
    return type;
}

- (BOOL)isIDType;
{
    return type == '@' && typeName == nil;
}

- (BOOL)isNamedObject;
{
    return type == T_NAMED_OBJECT;
}

- (BOOL)isTemplateType;
{
    return [typeName isTemplateType];
}

- (CDType *)subtype;
{
    return subtype;
}

- (CDTypeName *)typeName;
{
    return typeName;
}

- (NSArray *)members;
{
    return members;
}

- (BOOL)isModifierType;
{
    return type == 'r' || type == 'n' || type == 'N' || type == 'o' || type == 'O' || type == 'R' || type == 'V';
}

- (int)typeIgnoringModifiers;
{
    if ([self isModifierType] && subtype != nil)
        return [subtype typeIgnoringModifiers];

    return type;
}

- (NSUInteger)structureDepth;
{
    if (subtype != nil)
        return [subtype structureDepth];

    if (type == '{' || type == '(') {
        NSUInteger maxDepth = 0;

        for (CDType *member in members) {
            if (maxDepth < [member structureDepth])
                maxDepth = [member structureDepth];
        }

        return maxDepth + 1;
    }

    return 0;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] type: %d('%c'), name: %@, subtype: %@, bitfieldSize: %@, arraySize: %@, members: %@, variableName: %@",
                     NSStringFromClass([self class]), type, type, typeName, subtype, bitfieldSize, arraySize, members, variableName];
}

- (NSString *)formattedString:(NSString *)previousName formatter:(CDTypeFormatter *)typeFormatter level:(NSUInteger)level symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    NSString *result, *currentName;
    NSString *baseType, *memberString;

    assert(variableName == nil || previousName == nil);
    if (variableName != nil)
        currentName = variableName;
    else
        currentName = previousName;

    switch (type) {
      case T_NAMED_OBJECT:
          assert(typeName != nil);
          [symbolReferences addClassName:[typeName name]];
          if (currentName == nil)
              result = [NSString stringWithFormat:@"%@ *", typeName];
          else
              result = [NSString stringWithFormat:@"%@ *%@", typeName, currentName];
          break;

      case '@':
          if (currentName == nil) {
              if (protocols == nil)
                  result = @"id";
              else
                  result = [NSString stringWithFormat:@"id <%@>", [protocols componentsJoinedByString:@", "]];
          } else {
              if (protocols == nil)
                  result = [NSString stringWithFormat:@"id %@", currentName];
              else
                  result = [NSString stringWithFormat:@"id <%@> %@", [protocols componentsJoinedByString:@", "], currentName];
          }
          break;

      case 'b':
          if (currentName == nil) {
              // This actually compiles!
              result = [NSString stringWithFormat:@"unsigned int :%@", bitfieldSize];
          } else
              result = [NSString stringWithFormat:@"unsigned int %@:%@", currentName, bitfieldSize];
          break;

      case '[':
          if (currentName == nil)
              result = [NSString stringWithFormat:@"[%@]", arraySize];
          else
              result = [NSString stringWithFormat:@"%@[%@]", currentName, arraySize];

          result = [subtype formattedString:result formatter:typeFormatter level:level symbolReferences:symbolReferences];
          break;

      case '(':
          baseType = nil;
          /*if (typeName == nil || [@"?" isEqual:[typeName description]])*/ {
              NSString *typedefName;

              typedefName = [typeFormatter typedefNameForStruct:self level:level];
              if (typedefName != nil) {
                  baseType = typedefName;
              }
          }

          if (baseType == nil) {
              if (typeName == nil || [@"?" isEqual:[typeName description]])
                  baseType = @"union";
              else
                  baseType = [NSString stringWithFormat:@"union %@", typeName];

              if (([typeFormatter shouldAutoExpand] && [[typeFormatter typeController] shouldExpandType:self] && [members count] > 0)
                  || (level == 0 && [typeFormatter shouldExpand] && [members count] > 0))
                  memberString = [NSString stringWithFormat:@" {\n%@%@}",
                                           [self formattedStringForMembersAtLevel:level + 1 formatter:typeFormatter symbolReferences:symbolReferences],
                                           [NSString spacesIndentedToLevel:[typeFormatter baseLevel] + level spacesPerLevel:4]];
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
              NSString *typedefName;

              typedefName = [typeFormatter typedefNameForStruct:self level:level];
              if (typedefName != nil) {
                  baseType = typedefName;
              }
          }
          if (baseType == nil) {
              if (typeName == nil || [@"?" isEqual:[typeName description]])
                  baseType = @"struct";
              else
                  baseType = [NSString stringWithFormat:@"struct %@", typeName];

              if (([typeFormatter shouldAutoExpand] && [[typeFormatter typeController] shouldExpandType:self] && [members count] > 0)
                  || (level == 0 && [typeFormatter shouldExpand] && [members count] > 0))
                  memberString = [NSString stringWithFormat:@" {\n%@%@}",
                                           [self formattedStringForMembersAtLevel:level + 1 formatter:typeFormatter symbolReferences:symbolReferences],
                                           [NSString spacesIndentedToLevel:[typeFormatter baseLevel] + level spacesPerLevel:4]];
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

          if (subtype != nil && [subtype type] == '[')
              result = [NSString stringWithFormat:@"(%@)", result];

          result = [subtype formattedString:result formatter:typeFormatter level:level symbolReferences:symbolReferences];
          break;

      case 'r':
      case 'n':
      case 'N':
      case 'o':
      case 'O':
      case 'R':
      case 'V':
          if (subtype == nil) {
              if (currentName == nil)
                  result = [self formattedStringForSimpleType];
              else
                  result = [NSString stringWithFormat:@"%@ %@", [self formattedStringForSimpleType], currentName];
          } else
              result = [NSString stringWithFormat:@"%@ %@",
                                 [self formattedStringForSimpleType], [subtype formattedString:currentName formatter:typeFormatter level:level symbolReferences:symbolReferences]];
          break;

      default:
          if (currentName == nil)
              result = [self formattedStringForSimpleType];
          else
              result = [NSString stringWithFormat:@"%@ %@", [self formattedStringForSimpleType], currentName];
          break;
    }

    return result;
}

- (NSString *)formattedStringForMembersAtLevel:(NSUInteger)level formatter:(CDTypeFormatter *)typeFormatter symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    NSMutableString *str;

    assert(type == '{' || type == '(');
    str = [NSMutableString string];

    for (CDType *member in members) {
        [str appendString:[NSString spacesIndentedToLevel:[typeFormatter baseLevel] + level spacesPerLevel:4]];
        [str appendString:[member formattedString:nil
                                  formatter:typeFormatter
                                  level:level
                                  symbolReferences:symbolReferences]];
        [str appendString:@";\n"];
    }

    return str;
}

- (NSString *)formattedStringForSimpleType;
{
    // Ugly but simple:
    switch (type) {
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
      case 'B': return @"_Bool"; /* C99 _Bool or C++ bool */
      case 'v': return @"void";
      case '*': return @"STR";
      case '#': return @"Class";
      case ':': return @"SEL";
      case '%': return @"NXAtom";
      case '?': return @"void";
          //case '?': return @"UNKNOWN"; // For easier regression testing.
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

    switch (type) {
      case T_NAMED_OBJECT:
          assert(typeName != nil);
          if (shouldShowObjectTypes)
              result = [NSString stringWithFormat:@"@\"%@\"", typeName];
          else
              result = @"@";
          break;

      case '@':
          result = @"@";
          break;

      case 'b':
          result = [NSString stringWithFormat:@"b%@", bitfieldSize];
          break;

      case '[':
          result = [NSString stringWithFormat:@"[%@%@]", arraySize, [subtype _typeStringWithVariableNamesToLevel:level showObjectTypes:shouldShowObjectTypes]];
          break;

      case '(':
          if (typeName == nil) {
              return [NSString stringWithFormat:@"(%@)", [self _typeStringForMembersWithVariableNamesToLevel:level showObjectTypes:shouldShowObjectTypes]];
          } else if ([members count] == 0) {
              return [NSString stringWithFormat:@"(%@)", typeName];
          } else {
              return [NSString stringWithFormat:@"(%@=%@)", typeName, [self _typeStringForMembersWithVariableNamesToLevel:level showObjectTypes:shouldShowObjectTypes]];
          }
          break;

      case '{':
          if (typeName == nil) {
              return [NSString stringWithFormat:@"{%@}", [self _typeStringForMembersWithVariableNamesToLevel:level showObjectTypes:shouldShowObjectTypes]];
          } else if ([members count] == 0) {
              return [NSString stringWithFormat:@"{%@}", typeName];
          } else {
              return [NSString stringWithFormat:@"{%@=%@}", typeName, [self _typeStringForMembersWithVariableNamesToLevel:level showObjectTypes:shouldShowObjectTypes]];
          }
          break;

      case '^':
          result = [NSString stringWithFormat:@"^%@", [subtype _typeStringWithVariableNamesToLevel:level showObjectTypes:shouldShowObjectTypes]];
          break;

      case 'r':
      case 'n':
      case 'N':
      case 'o':
      case 'O':
      case 'R':
      case 'V':
          result = [NSString stringWithFormat:@"%c%@", type, [subtype _typeStringWithVariableNamesToLevel:level showObjectTypes:shouldShowObjectTypes]];
          break;

      default:
          result = [NSString stringWithFormat:@"%c", type];
          break;
    }

    return result;
}

- (NSString *)_typeStringForMembersWithVariableNamesToLevel:(NSInteger)level showObjectTypes:(BOOL)shouldShowObjectTypes;
{
    NSMutableString *str;

    assert(type == '{' || type == '(');
    str = [NSMutableString string];

    for (CDType *aMember in members) {
        if ([aMember variableName] != nil && level > 0)
            [str appendFormat:@"\"%@\"", [aMember variableName]];
        [str appendString:[aMember _typeStringWithVariableNamesToLevel:level - 1 showObjectTypes:shouldShowObjectTypes]];
    }

    return str;
}

// TODO (2009-08-26): Looks like this doesn't compare the variable name.
- (BOOL)isEqual:(CDType *)otherType;
{
    return [[self typeString] isEqual:[otherType typeString]];
}

// An easy deep copy.
- (id)copyWithZone:(NSZone *)zone;
{
    CDTypeParser *parser;
    NSError *error;
    NSString *str;
    CDType *copiedType;

    str = [self typeString];
    NSParameterAssert(str != nil);

    parser = [[CDTypeParser alloc] initWithType:str];
    copiedType = [[parser parseType:&error] retain];
    if (copiedType == nil)
        NSLog(@"Warning: Parsing type in -[CDType copyWithZone:] failed, %@", str);
    [parser release];

    NSParameterAssert([str isEqualToString:[copiedType typeString]]);

    [copiedType setVariableName:variableName];

    return copiedType;
}

- (BOOL)canMergeWithType:(CDType *)otherType;
{
    NSUInteger count, index;
    NSUInteger otherCount;
    NSArray *otherMembers;

    if ([self isIDType] && [otherType isNamedObject])
        return YES;

    if ([self isNamedObject] && [otherType isIDType]) {
        return YES;
    }

    if ([self type] != [otherType type]) {
        if (debugMerge) {
            NSLog(@"--------------------");
            NSLog(@"this: %@", [self typeString]);
            NSLog(@"other: %@", [otherType typeString]);
            NSLog(@"self isIDType? %u", [self isIDType]);
            NSLog(@"self isNamedObject? %u", [self isNamedObject]);
            NSLog(@"other isIDType? %u", [otherType isIDType]);
            NSLog(@"other isNamedObject? %u", [otherType isNamedObject]);
        }
        if (debugMerge) NSLog(@"%s, Can't merge because of type... %@ vs %@", _cmd, [self typeString], [otherType typeString]);
        return NO;
    }

    if (subtype != nil && [subtype canMergeWithType:[otherType subtype]] == NO) {
        if (debugMerge) NSLog(@"%s, Can't merge subtype", _cmd);
        return NO;
    }

    if (subtype == nil && [otherType subtype] != nil) {
        if (debugMerge) NSLog(@"%s, This subtype is nil, other isn't.", _cmd);
        return NO;
    }

    otherMembers = [otherType members];
    count = [members count];
    otherCount = [otherMembers count];

    //NSLog(@"members: %p", members);
    //NSLog(@"otherMembers: %p", otherMembers);
    //NSLog(@"%s, count: %u, otherCount: %u", _cmd, count, otherCount);

    if (count != 0 && otherCount == 0) {
        if (debugMerge) NSLog(@"%s, count != 0 && otherCount is 0", _cmd);
        return NO;
    }

    if (count != 0 && count != otherCount) {
        if (debugMerge) NSLog(@"%s, count != 0 && count != otherCount", _cmd);
        return NO;
    }

    // count == 0 is ok: we just have a name in that case.
    if (count == otherCount) {
        for (index = 0; index < count; index++) { // Oooh
            CDType *thisMember, *otherMember;
            CDTypeName *thisTypeName, *otherTypeName;
            NSString *thisVariableName, *otherVariableName;

            thisMember = [members objectAtIndex:index];
            otherMember = [otherMembers objectAtIndex:index];

            thisTypeName = [thisMember typeName];
            otherTypeName = [otherMember typeName];
            thisVariableName = [thisMember variableName];
            otherVariableName = [otherMember variableName];

            // It seems to be okay if one of them didn't have a name
            if (thisTypeName != nil && otherTypeName != nil && [thisTypeName isEqual:otherTypeName] == NO) {
                if (debugMerge) NSLog(@"%s, typeName mismatch on member %u", _cmd, index);
                return NO;
            }

            if (thisVariableName != nil && otherVariableName != nil && [thisVariableName isEqual:otherVariableName] == NO) {
                if (debugMerge) NSLog(@"%s, variableName mismatch on member %u", _cmd, index);
                return NO;
            }

            if ([thisMember canMergeWithType:otherMember] == NO) {
                if (debugMerge) NSLog(@"%s, Can't merge member %u", _cmd, index);
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
    NSString *before, *after;

    before = [self typeString];
    [self _recursivelyMergeWithType:otherType];
    after = [self typeString];
    if (debugMerge) {
        NSLog(@"----------------------------------------");
        NSLog(@"%s", _cmd);
        NSLog(@"before: %@", before);
        NSLog(@" after: %@", after);
        NSLog(@"----------------------------------------");
    }
}

- (void)_recursivelyMergeWithType:(CDType *)otherType;
{
    NSUInteger count, index;
    NSUInteger otherCount;
    NSArray *otherMembers;

    if ([self isIDType] && [otherType isNamedObject]) {
        //NSLog(@"thisType: %@", [self typeString]);
        //NSLog(@"otherType: %@", [otherType typeString]);
        type = T_NAMED_OBJECT;
        typeName = [[otherType typeName] copy];
        return;
    }

    if ([self isNamedObject] && [otherType isIDType]) {
        return;
    }

    if ([self type] != [otherType type]) {
        NSLog(@"Warning: Trying to merge different types in %s", _cmd);
        return;
    }

    [subtype _recursivelyMergeWithType:[otherType subtype]];

    otherMembers = [otherType members];
    count = [members count];
    otherCount = [otherMembers count];

    // The counts can be zero when we register structures that just have a name.  That happened while I was working on the
    // structure registration.
    if (otherCount == 0) {
        return;
    } else if (count == 0 && otherCount != 0) {
        NSParameterAssert(members != nil);
        [members removeAllObjects];
        [members addObjectsFromArray:otherMembers];
        //[self setMembers:otherMembers];
    } else if (count != otherCount) {
        // Not so bad after all.  Even kind of common.  Consider _flags.
        NSLog(@"Warning: Types have different number of members.  This is bad. (%d vs %d)", count, otherCount);
        NSLog(@"%@ vs %@", [self typeString], [otherType typeString]);
        return;
    }

    //NSLog(@"****************************************");
    for (index = 0; index < count; index++) {
        CDType *thisMember, *otherMember;
        CDTypeName *thisTypeName, *otherTypeName;
        NSString *thisVariableName, *otherVariableName;

        thisMember = [members objectAtIndex:index];
        otherMember = [otherMembers objectAtIndex:index];

        thisTypeName = [thisMember typeName];
        otherTypeName = [otherMember typeName];
        thisVariableName = [thisMember variableName];
        otherVariableName = [otherMember variableName];
        //NSLog(@"%d: type: %@ vs %@", index, thisTypeName, otherTypeName);
        //NSLog(@"%d: vari: %@ vs %@", index, thisVariableName, otherVariableName);

        if ((thisTypeName == nil && otherTypeName != nil) || (thisTypeName != nil && otherTypeName == nil))
            ; // It seems to be okay if one of them didn't have a name
            //NSLog(@"Warning: (1) type names don't match, %@ vs %@", thisTypeName, otherTypeName);
        else if (thisTypeName != nil && [thisTypeName isEqual:otherTypeName] == NO) {
            NSLog(@"Warning: (2) type names don't match:\n\t%@ vs \n\t%@.", thisTypeName, otherTypeName);
            // In this case, we should skip the merge.
        }

        if (otherVariableName != nil) {
            if (thisVariableName == nil)
                [thisMember setVariableName:otherVariableName];
            else if ([thisVariableName isEqual:otherVariableName] == NO)
                NSLog(@"Warning: Different variable names for same member...");
        }

        [thisMember _recursivelyMergeWithType:otherMember];
    }
}

- (void)generateMemberNames;
{
    if (type == '{' || type == '(') {
        NSSet *usedNames;
        unsigned int number;
        NSString *name;

        usedNames = [[NSSet alloc] initWithArray:[members arrayByMappingSelector:@selector(variableName)]];

        number = 1;
        for (CDType *aMember in members) {
            [aMember generateMemberNames];

            // Bitfields don't need a name.
            if ([aMember variableName] == nil && [aMember type] != 'b') {
                do {
                    name = [NSString stringWithFormat:@"_field%u", number++];
                } while ([usedNames containsObject:name]);
                [aMember setVariableName:name];
            }
        }

        [usedNames release];

    }

    [subtype generateMemberNames];
}

//
// Phase 0
//

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
    if (subtype != nil)
        [subtype phase0RegisterStructuresWithObject:typeController usedInMethod:isUsedInMethod];

    if ((type == '{' || type == '(') && [members count] > 0) {
        [typeController phase0RegisterStructure:self usedInMethod:isUsedInMethod];
    }
}

- (void)phase0RecursivelyFixStructureNames:(BOOL)flag;
{
    [subtype phase0RecursivelyFixStructureNames:flag];

    if ([[typeName name] hasPrefix:@"$"]) {
        if (flag) NSLog(@"%s, changing type name %@ to ?", _cmd, [typeName name]);
        [typeName setName:@"?"];
    }

    for (CDType *member in members)
        [member phase0RecursivelyFixStructureNames:flag];
}

//
// Phase 1
//

// Recursively go through type, registering structs/unions.
- (void)phase1RegisterStructuresWithObject:(CDTypeController *)typeController;
{
    // ^{ComponentInstanceRecord=}
    if (subtype != nil)
        [subtype phase1RegisterStructuresWithObject:typeController];

    if ((type == '{' || type == '(') && [members count] > 0) {
        [typeController phase1RegisterStructure:self];
        for (CDType *member in members)
            [member phase1RegisterStructuresWithObject:typeController];
    }
}

//
// Phase 2
//

// This wraps the recursive method, optionally logging if anything changed.
- (void)phase2MergeWithTypeController:(CDTypeController *)typeController debug:(BOOL)phase2Debug;
{
    NSString *before, *after;

    before = [self typeString];
    [self _phase2MergeWithTypeController:typeController debug:phase2Debug];
    after = [self typeString];
    if (phase2Debug && [before isEqualToString:after] == NO) {
        NSLog(@"----------------------------------------");
        NSLog(@"%s, merge changed type", _cmd);
        NSLog(@"before: %@", before);
        NSLog(@" after: %@", after);
    }
}

// Recursive, bottom-up
- (void)_phase2MergeWithTypeController:(CDTypeController *)typeController debug:(BOOL)phase2Debug;
{
    [subtype _phase2MergeWithTypeController:typeController debug:phase2Debug];

    for (CDType *member in members)
        [member _phase2MergeWithTypeController:typeController debug:phase2Debug];

    if ((type == '{' || type == '(') && [members count] > 0) {
        CDType *phase2Type;

        phase2Type = [typeController phase2ReplacementForType:self];
        if (phase2Type != nil) {
            // >0 members so we don't try replacing things like... {_xmlNode=^{_xmlNode}}
            if ([members count] > 0 && [self canMergeWithType:phase2Type]) {
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

//
// Phase 3
//

- (void)phase3RegisterWithTypeController:(CDTypeController *)typeController;
{
    [subtype phase3RegisterWithTypeController:typeController];

    if (type == '{' || type == '(') {
        [typeController phase3RegisterStructure:self /*count:1 usedInMethod:NO*/];
    }
}

- (void)phase3RegisterMembersWithTypeController:(CDTypeController *)typeController;
{
    //NSLog(@" > %s %@", _cmd, [self typeString]);
    for (CDType *member in members) {
        [member phase3RegisterWithTypeController:typeController];
    }
    //NSLog(@"<  %s", _cmd);
}

// Bottom-up
- (void)phase3MergeWithTypeController:(CDTypeController *)typeController;
{
    [subtype phase3MergeWithTypeController:typeController];

    for (CDType *member in members)
        [member phase3MergeWithTypeController:typeController];

    if ((type == '{' || type == '(') && [members count] > 0) {
        CDType *phase3Type;

        phase3Type = [typeController phase3ReplacementForType:self];
        if (phase3Type != nil) {
            // >0 members so we don't try replacing things like... {_xmlNode=^{_xmlNode}}
            if ([members count] > 0 && [self canMergeWithType:phase3Type]) {
                [self mergeWithType:phase3Type];
            } else {
                if (0) {
                    // This can happen in AU Lab, that struct has no members...
                    NSLog(@"Found phase3 type, but can't merge with it.");
                    NSLog(@"this: %@", [self typeString]);
                    NSLog(@"that: %@", [phase3Type typeString]);
                }
            }
        }
    }
}

@end
