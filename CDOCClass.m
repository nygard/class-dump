#import "CDOCClass.h"

#import <Foundation/Foundation.h>
#import "NSArray-Extensions.h"
#import "CDOCIvar.h"
#import "CDOCMethod.h"
#import "CDType.h"
#import "CDTypeParser.h"

@implementation CDOCClass

- (void)dealloc;
{
    [superClassName release];
    [ivars release];

    [super dealloc];
}

- (NSString *)superClassName;
{
    return superClassName;
}

- (void)setSuperClassName:(NSString *)newSuperClassName;
{
    if (newSuperClassName == superClassName)
        return;

    [superClassName release];
    superClassName = [newSuperClassName retain];
}

- (NSArray *)ivars;
{
    return ivars;
}

- (void)setIvars:(NSArray *)newIvars;
{
    if (newIvars == ivars)
        return;

    [ivars makeObjectsPerformSelector:@selector(setOCClass:) withObject:nil];
    [ivars release];
    ivars = [newIvars retain];
    [ivars makeObjectsPerformSelector:@selector(setOCClass:) withObject:self];
}

- (void)appendToString:(NSMutableString *)resultString;
{
    NSArray *sortedMethods;
    int count, index;

    [resultString appendFormat:@"@interface %@", name];
    if (superClassName != nil)
        [resultString appendFormat:@":%@", superClassName]; // Add space later, keep this way for backwards compatability

    if ([protocols count] > 0)
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];

    [resultString appendString:@"\n{\n"];
    count = [ivars count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            [[ivars objectAtIndex:index] appendToString:resultString];
            [resultString appendString:@"\n"];
        }
    }

    [resultString appendString:@"}\n\n"];

    sortedMethods = [classMethods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    count = [sortedMethods count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            [resultString appendString:@"+ "];
            [[sortedMethods objectAtIndex:index] appendToString:resultString];
            [resultString appendString:@"\n"];
        }
    }

    sortedMethods = [instanceMethods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    count = [sortedMethods count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            [resultString appendString:@"- "];
            [[sortedMethods objectAtIndex:index] appendToString:resultString];
            [resultString appendString:@"\n"];
        }
    }

    if ([classMethods count] > 0 || [instanceMethods count] > 0)
        [resultString appendString:@"\n"];
    [resultString appendString:@"@end\n\n"];
}

- (void)registerStructsWithObject:(id <CDStructRegistration>)anObject;
{
    [super registerStructsWithObject:anObject];
#if 1
 {
     int count, index;
     CDTypeParser *parser;

     count = [ivars count];
     for (index = 0; index < count; index++) {
         CDType *structType;

         parser = [[CDTypeParser alloc] initWithType:[(CDOCIvar *)[ivars objectAtIndex:index] type]];
         structType = [parser parseType];
         if ([[self name] isEqual:@"NSInvocation"] == YES) {
             NSLog(@"Registering struct for %@: %@", [self name], [structType typeString]);
         }
         [structType registerStructsWithObject:anObject];
         [parser release];
     }
 }
#endif
}

@end
