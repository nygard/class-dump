#import "CDOCSymtab.h"

#import <Foundation/Foundation.h>

@implementation CDOCSymtab

- (id)init;
{
    if ([super init] == nil)
        return nil;

    return self;
}

- (void)dealloc;
{
    [classes release];
    [categories release];

    [super dealloc];
}

@end
