// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import "CDType.h"

#import <Foundation/Foundation.h>
#import "NSString-Extensions.h"
#import "CDTypeLexer.h" // For T_NAMED_OBJECT

@implementation CDType

- (id)init;
{
    if ([super init] == nil)
        return nil;

    type = 0; // ??
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

- (id)initIDType:(NSString *)aName;
{
    if ([self init] == nil)
        return nil;

    if (aName != nil) {
        type = '^';
        subtype = [[CDType alloc] initNamedType:aName];
    } else {
        type = '@';
    }

    return self;
}

- (id)initNamedType:(NSString *)aName;
{
    if ([self init] == nil)
        return nil;

    type = T_NAMED_OBJECT;
    typeName = [aName retain];

    return self;
}

- (id)initStructType:(NSString *)aName members:(NSArray *)someMembers;
{
    if ([self init] == nil)
        return nil;

    type = '{';
    typeName = [aName retain];
    members = [someMembers retain];

    return self;
}

- (id)initUnionType:(NSString *)aName members:(NSArray *)someMembers;
{
    if ([self init] == nil)
        return nil;

    type = '(';
    typeName = [aName retain];
    members = [someMembers retain];

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
    [subtype release];
    [typeName release];
    [members release];
    [variableName release];
    [bitfieldSize release];
    [arraySize release];

    [super dealloc];
}

- (NSString *)variableName;
{
    return variableName;
}

- (void)setVariableName:(NSString *)newVariableName;
{
    if (newVariableName == variableName)
        return;

    [variableName release];
    variableName = [newVariableName retain];
}

- (int)type;
{
    return type;
}

- (BOOL)isIDType;
{
    return type == '@' && typeName == nil;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] type: %d('%c'), name: %@, subtype: %@, bitfieldSize: %@, arraySize: %@, members: %@, variableName: %@",
                     NSStringFromClass([self class]), type, type, typeName, subtype, bitfieldSize, arraySize, members, variableName];
}

- (NSString *)formattedString:(NSString *)inner expand:(BOOL)shouldExpand level:(int)level;
{
    NSString *tmp;
    NSString *name, *type_name;
#if 0
    if (t == NULL)
        return inner;
#endif
    if (inner == nil)
        inner = @"";

    switch (type) {
      case T_NAMED_OBJECT:
          if (variableName == nil)
              name = @"";
          else
              name = [NSString stringWithFormat:@" %@", variableName];

          tmp = [NSString stringWithFormat:@"%@%@ %@", typeName, name, inner]; // We always have a pointer to this type
          break;

      case '@':
          if (variableName == nil)
              name = @"";
          else
              name = [NSString stringWithFormat:@" %@", variableName];

          if ([inner length] > 0)
              tmp = [NSString stringWithFormat:@"id%@ %@", name, inner];
          else
              tmp = [NSString stringWithFormat:@"id%@%@", name, inner];
          break;

      case 'b':
          // TODO (2003-12-19): This is different from previous... why?
          if (variableName == nil)
              name = @"";
          else
              name = [NSString stringWithFormat:@"%@", variableName];

          tmp = [NSString stringWithFormat:@"int %@:%@%@", name, bitfieldSize, inner];
          break;

      case '[':
          if (variableName == nil)
              name = @"";
          else
              name = [NSString stringWithFormat:@"%@", variableName];

          tmp = [NSString stringWithFormat:@"%@%@[%@]", inner, name, arraySize];
          tmp = [subtype formattedString:tmp expand:shouldExpand level:level];
          break;

      case '(':
          if (variableName == nil || [variableName hasPrefix:@"?"] == YES)
              name = @"";
          else
              name = [NSString stringWithFormat:@"%@", variableName];

          if (typeName == nil)
              type_name = @"";
          else
              type_name = [NSString stringWithFormat:@" %@", typeName];

          tmp = [NSString stringWithFormat:@"union%@", type_name];
          if (shouldExpand == YES && subtype != nil) {
              tmp = [NSString stringWithFormat:@"%@ {\n%@%@}",
                              tmp, [subtype formattedStringForMembersAtLevel:level + 1], [NSString spacesIndentedToLevel:level spacesPerLevel:2]];
          }

          if ([inner length] > 0 || [name length] > 0) {
              tmp = [NSString stringWithFormat:@"%@ %@%@", tmp, inner, name];
          }
          break;

      case '{':
          if (variableName == nil || [variableName hasPrefix:@"?"] == YES)
              name = @"";
          else
              name = [NSString stringWithFormat:@"%@", variableName];

          if (typeName == nil)
              type_name = @"";
          else
              type_name = [NSString stringWithFormat:@" %@", typeName];

          tmp = [NSString stringWithFormat:@"struct%@", type_name];

          if (shouldExpand == YES && subtype != nil) {
              tmp = [NSString stringWithFormat:@"%@ {\n%@%@}",
                              tmp, [subtype formattedStringForMembersAtLevel:level + 1], [NSString spacesIndentedToLevel:level spacesPerLevel:2]];
          }

          if ([inner length] > 0 || [name length] > 0) {
              tmp = [NSString stringWithFormat:@"%@ %@%@", tmp, inner, name];
          }
          break;

      case '^':
          if (variableName == nil)
              name = @"";
          else
              name = [NSString stringWithFormat:@"%@", variableName];

          if (subtype != nil && [subtype type] == '[')
              tmp = [NSString stringWithFormat:@"(*%@%@)", inner, name];
          else
              tmp = [NSString stringWithFormat:@"*%@%@", name, inner];

          tmp = [subtype formattedString:tmp expand:shouldExpand level:level];
          break;

      case 'r':
      case 'n':
      case 'N':
      case 'o':
      case 'O':
      case 'R':
      case 'V':
          tmp = [subtype formattedString:inner expand:shouldExpand level:level];
          tmp = [NSString stringWithFormat:@"%@ %@", [self formattedStringForSimpleType], tmp];
          break;

      default:
          if (variableName == nil)
              name = @"";
          else
              name = [NSString stringWithFormat:@"%@", variableName];

          if ([name length] == 0 && [inner length] == 0)
              tmp = [self formattedStringForSimpleType];
          else
              tmp = [NSString stringWithFormat:@"%@ %@%@", [self formattedStringForSimpleType], name, inner];
          break;
    }

    return tmp;
}

- (NSString *)formattedStringForMembersAtLevel:(int)level;
{
    NSMutableString *str;
    int count, index;

    assert(type == '{' || type == '(');
    str = [NSMutableString string];

    count = [members count];
    for (index = 0; index < count; index++) {
        [str appendString:[NSString spacesIndentedToLevel:level spacesPerLevel:2]];
        [str appendString:[[members objectAtIndex:index] formattedString:nil expand:YES level:level]];
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
          //case '?': return @"void /*UNKNOWN*/";
      case '?': return @"UNKNOWN"; // For easier regression testing.  TODO (2003-12-14): Change this back to void
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

@end
