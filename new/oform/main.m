#import <Foundation/Foundation.h>
#import "OFObjCTypeFormatter.h"

int main (int argc, const char *argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    // insert your code here
    [OFObjCTypeFormatter test];
    
    [pool release];
    exit(0);
}
