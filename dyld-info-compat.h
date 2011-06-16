#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_6

// This is taken from loader.h on 10.7, so that I can still compile for 10.6.

#define LC_DYLD_ENVIRONMENT 0x27 /* string for dyld to treat like environment variable */

#endif
