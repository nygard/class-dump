//
//  objc-symbols
//

#include <getopt.h>
#include <mach-o/arch.h>
#include <sysexits.h>

#import <Foundation/Foundation.h>

#import "CDMachOFile.h"
#import "CDFatFile.h"
#import "CDObjectiveCProcessor.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDOCMethod.h"
#import "NSString-CDExtensions.h"

void print_usage(void)
{
	fprintf(stderr,
	        "Usage: objc-symbols [options] <stripped file>\n"
	        "\n"
	        "  where options are:\n"
	        "		--arch <arch>  choose a specific architecture from a universal binary (ppc, ppc64, i386, x86_64, armv6, armv7, armv7s)\n");
}

void dump_objc_symbols(CDMachOFile *machOFile)
{
	CDObjectiveCProcessor *processor = [[[machOFile processorClass] alloc] initWithMachOFile:machOFile];
	[processor process];
	
	NSArray *classes = [processor valueForKey:@"classes"];
	NSArray *categories = [processor valueForKey:@"categories"];
	for (CDOCClass *class in [classes arrayByAddingObjectsFromArray:categories])
	{
		NSString *categoryName = [class isKindOfClass:[CDOCCategory class]] ? ((CDOCCategory *)class).className : nil;
		NSInteger idx = 0;
		for (NSArray *methods in @[ class.classMethods, class.instanceMethods ])
		{
			BOOL isClassMethod = idx == 0;
			for (CDOCMethod *method in methods)
			{
				printf("%0*lx", (int)machOFile.ptrSize * 2, method.address);
				const char *methodClass = categoryName ? [categoryName UTF8String] : [class.name UTF8String];
				const char *methodCategory = categoryName ? [[NSString stringWithFormat:@"(%@)", class.name] UTF8String] : "";
				printf("\t%c[%s%s %s]\n", isClassMethod ? '+' : '-', methodClass, methodCategory, [method.name UTF8String]);
			}
			idx++;
		}
	}
}

int main(int argc, const char * argv[])
{
	@autoreleasepool
	{
		if (argc == 1)
		{
			print_usage();
			exit(EX_OK);
		}
		
		int ch;
		BOOL errorFlag = NO;
		CDArch targetArch = {CPU_TYPE_ANY, CPU_TYPE_ANY};
		
		struct option longopts[] = {
			{ "arch", required_argument, NULL, 'a' },
			{ NULL,   0,				 NULL, 0 },
		};
		
		while ( (ch = getopt_long(argc, (char *const*)argv, "a:", longopts, NULL)) != -1)
		{
			switch (ch)
			{
				case 'a': {
					NSString *name = [NSString stringWithUTF8String:optarg];
					targetArch = CDArchFromName(name);
					if (targetArch.cputype == CPU_TYPE_ANY)
					{
						fprintf(stderr, "Error: Unknown arch %s\n\n", optarg);
						errorFlag = YES;
					}
					break;
				}
				case '?':
				default:
					errorFlag = YES;
					break;
			}
		}
		
		argc -= optind;
		argv += optind;
		
		if (errorFlag || argc < 1)
		{
			print_usage();
			exit(EX_USAGE);
		}

		NSString *inputFile = [NSString stringWithUTF8String:argv[0]];
		CDFile *file = [CDFile fileWithContentsOfFile:inputFile searchPathState:nil];
		if (file == nil)
		{
			fprintf(stderr, "Error: input file is neither a Mach-O file nor a fat archive.\n");
			exit(EX_DATAERR);
		}
		
		if (targetArch.cputype == CPU_TYPE_ANY)
			[file bestMatchForLocalArch:&targetArch];
		
		CDMachOFile *machOFile = [file machOFileWithArch:targetArch];
		if (!machOFile)
		{
			NSString *targetArchName = CDNameForCPUType(targetArch.cputype, targetArch.cpusubtype);
			if ([file isKindOfClass:[CDFatFile class]] && [(CDFatFile *)file containsArchitecture:targetArch])
				fprintf(stderr, "Fat file doesn't contain a valid Mach-O file for the specified architecture (%s). "
				                "It probably means that objc-symbols was run on a static library, which is not supported.\n", [targetArchName UTF8String]);
			else
				fprintf(stderr, "File doesn't contain the specified architecture (%s). Available architectures are %s.\n", [targetArchName UTF8String], [file.architectureNameDescription UTF8String]);
			
			exit(EX_USAGE);
		}
		
		dump_objc_symbols(machOFile);
		
		exit(EX_OK);
	}
}

