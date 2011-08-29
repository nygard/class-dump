#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_6

// This is taken from loader.h on 10.7, so that I can still compile for 10.6.

#define	LC_LOAD_UPWARD_DYLIB (0x23 | LC_REQ_DYLD) /* load upward dylib */
#define LC_VERSION_MIN_MACOSX 0x24   /* build for MacOSX min OS version */
#define LC_VERSION_MIN_IPHONEOS 0x25 /* build for iPhoneOS min OS version */
#define LC_FUNCTION_STARTS 0x26 /* compressed table of function start addresses */
#define LC_DYLD_ENVIRONMENT 0x27 /* string for dyld to treat like environment variable */

/*
 * The version_min_command contains the min OS version on which this 
 * binary was built to run.
 */
struct version_min_command {
    uint32_t	cmd;		/* LC_VERSION_MIN_MACOSX or LC_VERSION_MIN_IPHONEOS  */
    uint32_t	cmdsize;	/* sizeof(struct min_version_command) */
    uint32_t	version;	/* X.Y.Z is encoded in nibbles xxxx.yy.zz */
    uint32_t	reserved;	/* zero */
};

#endif
