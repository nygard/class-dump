### Version 3.5 - Released 2013-11-16

* Targeting 10.8+ now, and building with the 10.9 SDK.
* Fixed Objective-C 2.0 ivar offsets. It now displays actual offsets instead of ivar addresses.
* Support for the new `arm64` architecture.
  * Recognize the `--arch arm64` option
  * Display `arm64` instead of `0x100000c:0x0`
  * Handle the new `LC_ENCRYPTION_INFO_64` load command
* Parse extended types when available. It means that you can extract more precise type information on protocol methods. E.g. you get `- (NSArray *)bookmarksFromContentItems:(NSArray *)arg1;` instead of `- (id)bookmarksFromContentItems:(id)arg1;`. Unfortunately, extended types are not available on classes, only on protocols.
* Parse blocks type information, i.e. you get `CDUnknownBlockType` instead of `id`. Inside protocol methods – thanks to extended types – you get the full block signature, e.g. `- (void)accountsWithHandler:(void (^)(NSArray *, NSError *))arg1;`.
* Resolve `@loader_path`. Xcode and the developer tools use this.
* Added the `--hide` options to hide struct/union and protocol sections. Use `--hide structures` and `--hide protocols` or `--hide all` to hide both of those. This is meant for development, to make it easier to see just the other sections.
* Tweaked comments, now using `//` instead of `/* */` in generated headers.
* Show a better error message when trying to run class-dump on a static library.
* Fix the way the ObjC 2 list header `entsize` field is read. This allows to run class-dump on files produced by the latest version of [dyld_decache](https://github.com/kennytm/Miscellaneous#dyld_decache).
* Parse the `LC_FUNCTION_STARTS` load command.

### Version 3.4 - Released 2012-11-19

* Targeting 10.7+ now. Needs to build with the 10.8 SDK.
* Lots of changes to the code. Style changes. Using automatic reference counting. Objective-C literals and array/dictionary indexing.
* Recognise `armv7s` architecture.
* Fixed a bug where `--arch x86_64` wouldn’t find the correct architecture.
* Handle 4 new load commands from 10.8:
  * `LC_MAIN`
  * `LC_DATA_IN_CODE`
  * `LC_SOURCE_VERSION`
  * `LC_DYLIB_CODE_SIGN_DRS`
* Show source and SDK versions.
* Fix crasher on SDK frameworks, which have empty sections.
* deprotect fat files, endian neutral, better error messages. [0xced]
* Use `__attribute__((visibility(“hidden”)))` instead of `// Not exported` [0xced]
* Show a more informative error message when the file doesn’t contain the desired architecture.
* Switch to `NSRegularExpression` for `-C` arg matching.

### Version 3.3.4 - Released 2011-09-03

* Fixed assertion failure on many frameworks in Lion.
* Replaced SDK aliases with new command line options, `--sdk-ios` and `--sdk-mac`. Now you can use `--sdk-ios 5.0`
* Handle another type: @encode(long double) = D
* Handle `_Complex`. This finally fixes the parse error with Grapher.app
* Added support for minimum Mac OS X and iOS versions (`LC_VERSION_MIN_MACOSX`, `LC_VERSION_MIN_IPHONEOS`).
* Show `LC_DYLD_ENVIRONMENT` information.
* Updated deployment target to 10.6
* Fixed logs about some unknown load commands.
  * `LC_LOAD_UPWARD_DYLIB` - treat this just like `LC_LOAD_DYLIB`
  * `LC_FUNCTION_STARTS` - we don’t do anything with this command, just stopped the warning
* I’ve switched to git, and moved the repository to github. The latest source is now available at the [class-dump git repository at github](http://github.com/nygard/class-dump).

#### Known Bugs

* Assertion failure on an older version Kindle.app
  * This may be caused by optional methods in protocols.

### Version 3.3.3 - Released 2010-08-08

* Fixed problems where many iOS class names were missing or appeared as “(null)”/”__objc_empty_cache”.
* Added `--sdk-root` option to let you specify a root path to search for frameworks. You can use a path, or short aliases: 4.1, 4.0, 3.2, 10.6, 10.5
* Resolve and use run paths, and show each resolved path. Xcode and the developer tools use this.
* Report the correct name of architectures that use 64 bit ABI.
* A few visible changes contributed by Cédric Luthi, and many more in the code:
  * Added a comment above @interface of classes that are not exported.
  * Fix to find first read/write segment (i.e. Accelerate i386 framework).
  * Show UUID under filename.
* ~~The latest source is now available at the [class-dump Mercurial repository at bitbucket.org](http://bitbucket.org/nygard/class-dump).~~
* 2011-05-12: I’ve switched to git, and moved the repository to github. The latest source is now available at the [class-dump git repository at github](http://github.com/nygard/class-dump).
 
### Version 3.3.2 - Released 2010-05-11

* The `-a` and `-A` options should work again.
* Better error reporting for non-existent and unreadable files. (Patch from Gerriet M. Denkmann)
* Added missing classes to one of the targets.

### Version 3.3.1 - Released 2009-09-17

* Handle 10.6 style protected binaries, so that you can once again class-dump Finder, Dock, SystemUIServer, etc.
* Fixed crasher when trying to dump 64-bit files with 32-bit class-dump. This now prints an error message.
* Generate and use typedefs for template types that are used in methods.

### Version 3.3 - Released 2009-09-01

* Added support for more property attributes:
  * Dynamic attributes (D) now show `// @dynamic prop;`
  * Weak and strong (W, P). Strong is the default, only appears when garbage collection is enabled. `@property(readonly) __weak NSObject *object;`
  * Nonatomic (N). It looks like current versions of gcc don’t generate this, but it was used in the past.
  * Thanks to Joe Ranieri ([alacatia labs](http://www.alacatialabs.com/)) for sending a patch to handle these property attributes.
* Added support for types with C++ templates in property attributes. Since these types contain commas, we can’t just split the attribute string on commas. Now it parses the type directly from the attribute string.
* Improved parsing of types with C++ templates. It can now make it through Safari and WebKit without complaint.
* Fixed crasher when trying to class-dump Finder.
* Fixed some memory leaks and other errors discovered by the Clang Static Analyzer. What a great tool!
* Mac OS X prefers 64-bit executables over 32-bit executables, so there is no need to have class-dump-32. Now class-dump is built 32/64 bit Universal.
* Recognize more load commands so it doesn’t complain about them.
* Recognize encrypted iPhone apps (`LC_ENCRYPTION_INFO`) so that it doesn’t print a bunch of garbage.
* Changed the way I handle structures. This is the part that gathers all of the structure types, merges member names, merges id types with object pointers, figures out which can be expanded inline and which must be declared at the top, and then chooses typedef names. For the most part, it works better than before, although there may be problems for things like Safari, WebKit, iPhoto.
  * Changed anonymous structure/union typedef names from being numbered based on the order they were encountered (which was very susceptible to changes in the code or the target files), to using a hash based on the type string. This should result in smaller, more meaningful diffs between versions of a target file. For example, only 6 differences versus 78 between the i386 AppKit 10.5.5 and 10.5.8.

### Version 3.2 - Released 2009-07-01

* This version is compiled for Mac OS X 10.5 or later. Both 64 and 32 bit executables are included.
* Added support for Objective-C 2.0, on both 32 bit (iPhone) and 64 bit (Mac OS X).
  * Display optional class and instance methods in protocols.
  * Handle class properties. Unrecognized property attributes are noted in a comment on the following line.
* Added support for 64-bit files. This is only available for 64-bit versions of class-dump. For older systems, a 32-bit version is provided as class-dump-32.
* You can specify architectures as `<cpu type>:<cpu subtype>`, values are hex with an optional `0x` prefix. For example, you can use `--arch 0xc:0x6` or simply `--arch c:6`. The `--list-arches` option will also list unknown architectures in this format.

### Version 3.1.2 - Released 2007-11-08

* This version should work on Mac OS X 10.4+. I expect the next release will require 10.5.
* Added `-f` option to find a string in a method name. The results are shown in context, so you can see the class, category, or protocol that contains the matching methods. The string is case sensitive, and not a regular expression.
* Recognize protected segments, so we don’t print a lot of garbage when the strings for names, types, arguments fall inside a protected segment. (Thanks to Dave Benvenuti for finding this bug.)
* Generate header files for protocols when using `-H`. (Requested by Gregor Riepl.)
  * I’ve added a dash to the `#import <protocol_name>-Protocol.h`, so they stand out more against things like `NSURLProtocol.h`, which are regular classes.
* Converted all of the unit tests from ObjcUnit to OCUnit/SenTestKit.
* Use -[NSBundle executablePath] instead of a bunch of custom code that does the same thing. This also lets it understand other bundle types, like preference panes. Thanks to Dave Vasilevsky for this patch.
* I’ve been tweaking the parsing of types that include C++ template information in them.
  * Type parsing with C++ templates, handles spaces between trailing >’s. Improves TextMate output, among others.
  * Handle case where there is more than one quoted string in a row in structure definitions. We just concatenate the strings (with `__` between them). This was first seen in TextMate 1.5.4. Many of the structs now show their proper name, instead of getting assigned _field# names.
  * Preprocess type strings before parsing, replacing `<unnamed>::` with `unnamed::`. This makes Pages ‘08 dump without error. It has types like `std::allocator<<unnamed>::AnimationChunk>` in it.
* Better error reporting from parsing type errors. It adds a comment at the end of a method prototype if there were fewer types than arguments. For example, from TextMate:
  * `- (struct _NSPoint)iteratorPosition: /* Error: Ran out of types for this method. */;`
* Show a better warning for frameworks that don’t have an executable file, such as these:
  * `/System/Library/Frameworks/Kernel.framework`
  * `/System/Library/Frameworks/JavaEOCocoa.framework`
* Added `--list-arches` option. This lists the architectures available in a file, in a very short form that is easy to use from a shell script, and then exits. It’s like a terse form of `lipo -info`. I use this in my regression testing to dump all available architectures.

### Version 3.1.1 - Released 2006-11-12

* This version will only run on Mac OS X 10.4 (or later).
* Fixed some old bugs with parsing C++ template types, which occurred frequently with applications like iPhoto. It doesn’t try to parse these types—it just scans for commas, nested < and >, and the closing >.
* Show a message indicating that a file doesn’t contain any Objective-C runtime information, instead of showing the header and nothing else.
* Added option `-t` (`--suppress-header`), to not show the header comment at the top of the file. This will make it easier to do regression testing for the next release.

### Version 3.1 - Released 2005-08-16

* This version will only run on Mac OS X 10.4 (or later).
* Added support for universal binaries. This works better than it ever did before, and can actually dump binaries for architectures with a different endianess.
  * Added a `--arch` command line option to select the architecture. (ppc or i386)
* Fixed a bug that caused a crash when the Mach-O file of a wrapper was a link to outside of the wrapper.
* Fixed crasher when run on `/System/Library/Frameworks/System.framework`.

### Version 3.0 - Released 2004-02-18

* Integrated several outstanding patches:
  * Anjo Krank added an option, `-I`, to sort the classes by dependancy.  
  * Kurt Revis made some changes to support filenames that contain some non-ASCII characters.
  * Jonathan Rentzsch added an option, `-H`, to generate separate header files for each class and protocol.
  * Stéphane Corthésy made some changes:
    * all error messages are prefixed by `//` to have a C comment line instead
    * `struct ?` no longer appears
    * protocols no longer display an IMP address
    * compiles with gcc 3.3 on Panther
* Changes to options:
  * Removed old `-s` option. Now we always use `char *` instead of `STR`.
  * Split sorting option into `-s` to sort classes and categories, and `-S` to sort methods.
  * Removed old `-R` option. Now protocols are always recursively expanded.
  * Added `-H` and `-I` options. See above.
  * Added `-o` option to specify output path for `-H`.
  * Removed the `-e` option for expanding structures. This has been replaced with much better structure handling. See below.
* Improved structure handling:
  * The old `-e` option would expand structures in place, including method declarations. You could see what the structures were, but it was messy and wouldn’t even come close to compiling.
  * We now gather all of the structures and unions together and show the definitions at the top of the output. Normal declarations for structs and unions that have names, and typedefs for anonymous structs/unions which used to appear as `struct ?`.
  * Sometimes the structure members have names and other times they don’t, so we merge the information together. Named structures are easy to merge. Anonymous structures (used to appear as `struct ?`) are merged if they have the same member types and there is an unambiguous choice of what to merge based on the information we have.
  * If an anonymous structure is used only once as an ivar (such as for storing flags) or as a member of another structure then it is expanded inline. Otherwise a typedef in generated for that structure and that name is used everywhere else. The typedef names are of the form `CDAnonymousStruct<number>` and `CDAnonymousUnion<number>`, numbered to make unique names.
  * Structure members without names have names generated for them, in the form `_field<number>`, except for bitfields (they compile without names). There is a known bug where they don’t always get named.
* It now understands `@executable_path`, so you can recursively dump apps with frameworks bundled in the app wrapper.
* Fixed some parsing errors with C++ template types. We also keep track of the template types and show them in the output. The generated structures probably won’t compile, though.
* Unmodified char types are shown as BOOL, which is correct in most cases. Char pointers are untouched.
* It now shows class methods for protocols. For example, Foundation’s NSURLDownloadDecoder has two class methods.
* It now shows protocols adopted by categories. For example, Foundation’s NSURLConnection(NSURLAuthenticationChallengeSender) category adopts the NSURLAuthenticationChallengeSender protocol.
* Removed extra blank line before @end in classes without methods.
* Changed type of bitfields from int to unsigned int, so you don’t get a warning with single bit bitfields.
* Fixed some places where we showed protocols without any methods, even though they should have methods. For example, Foundation’s NSURLDataDecoder has two methods.
* Some protocols were missing, but we now show them. For example, Foundation’s NSConnectionProtocol and NSProtocolCheckerForwardingMethods protocols.
* The order of methods shown in protocols should now match the order they were defined in the source file. In previous versions the methods were reversed.
* The code has changed significantly since the previous release, generally for the better. It should be easier to understand now. I’ve removed support for OSes prior to Mac OS X. I’ve replaced the Yacc grammar with an Objective-C parser. I’ve only compiled and tested this on 10.3, but it should compile on earlier releases.
* Added some unit tests for formatting types. I’m using [ObjcUnit](http://oops.se/objcunit/).

### Version 2.1.5-wolf

* Unofficial patch on 2.1.5 by Jonathan ‘Wolf’ Rentzsch.
  * Added `-H` header file generation option. Instead of just writing out a single long stream of ObjC header code, the `-H` option will attempt to create one header (.h) file per ObjC class, category and protocol. It uses heuristics to generate the correct #import statements, though circular references need to be manually fixed up with a forward declaration somewhere. Header files are generated within the current directory, so be sure you’re in the directory you want to populate first, or you may have a mess to clean up!  [Weblog entry](http://web.archive.org/web/20090430082404/http://rentzsch.com/notes/class-dumpHeaders).

### Version 2.1.5 - Released 2001-03-27

* Compiled on Mac OS X. The release notes say *Do Not Use Pre-GM Compilers to Build Software for Mac OS X*, so I’ve recompiled this.
* No changes other than the version number and README.

### Version 2.1.4 - Released 2000-10-15

* Carl Lindberg made some changes that make class-dump work better on Mac OS X Public Beta:
  * It’s a little better about backward compatibility with old frameworks that still work on Public Beta.
  * It fixes most of the syntax errors we were getting when parsing types. (We were having trouble with union types.)
* It now understands framework install names and the framework search path, so you should be able to run it on apps or frameworks where the install name of the frameworks is not where the framework exists in the filesystem. The Omni frameworks, for example, change the install name.
* It will search for an app executable in the Contents/MacOS directory of the app wrapper that Mac OS X uses if you just use the path to the main app wrapper.
* You can set the `ClassDumpDebugFrameworkPaths` environment variable to see the steps it’s going through to find the frameworks. It spits out a lot of stuff, but it may be useful for someone. With zsh, you can do this:
  * `ClassDumpDebugFrameworkPaths=YES class-dump /System/Applications/MailViewer.app`

### Version 2.1.3 - Released 2000-06-23

* James McIlree made these changes to get class-dump running on Mac OS X DP4:
  * The OS X Mach-O files keep some information in the `__TEXT __cstring` section. I’ve made a small set of tweeks to cause class-dump to look in the correct segment and section.
  * The build on OS X defines `NS_TARGET_MAJOR` as 5, this needs to be set in order to get the new code.

### Version 2.1.2 - Released 1998-07-28

* Tom Hageman has provided the changes to make it work with object files and bundles. In the previous version, the output was empty.
* It shouldn’t crash if there are fewer types than it expects while formatting a method. This is most likely triggered by incompatible current versions of frameworks.

### Version 2.1.1 - Released 199?-??-??

* Compiles under Rhapsody, Openstep and Foundation based NeXTSTEP 3.3. Tom Hageman provided the changes to get it working with NeXTSTEP 3.3 and compiled it quad-fat.
* Under Rhapsody, the `-C` option now takes egrep style regular expressions to match categories and protocols. It will still work as before with text strings, but you can, for example, specify `-C 'View|Window'` to match classes with both strings.

### Version 2.1.0 - Released 1997-10-09

* The `-a` option has been split into `-a`, which just shows instance variable offsets, and `-A`, which shows method addresses. (Suggested by Charles Lloyd.)
* Protocol definitions are all printed at the beginning of the output for each file. Duplicate protocol definitions are no longer shown.
* New option, `-S`, to sort the output. Protocols are sorted by name. Classes and categories are sorted by name. Class and instance methods are each sorted by name. (Suggested by Charles Lloyd.)
* When the `-S` option is not used, the method definitions are printed out reversed from the order they are found in the Mach-O file. This should reflect the order they are declared in the original source file.
* The effect of the `-C` option has changed. It now matches category and protocol names instead of just class names. (Carl Lindberg pointed out that categories should also be matched.)
* Corrected output when the target file doesn’t have an Objective-C segment.
* An `id *` type should now be printed correctly.
* Fixed printing of pointers to arrays.
* Fixed printing of multi-dimensional arrays.
* Made #ifdefs of `LC_PREBOUND_DYLIB` and `LC_LOAD_DYLIB` independent for compiling under 3.3 (Suggested by Carl Lindberg.)
* This now uses the Foundation framework, so it may not work with NeXTSTEP 3.x.
* flex is no longer required.
* The version number of class-dump is now included in the output.

### Version 2.0 - Released 1997-01-27

* class-dump works with framework based files (the whole point of this exercise!)
* The class declaration shows the adopted protocols.
* Protocol definitions are shown before (rather than after) the class declaration.
* New option, `-r`, to recursively expand frameworks and fixed VM shared libraries.
* A comment is generated to show the file where the classes are defined. This is helpful when using the `-r` option.
* New option, `-s`, to use `char *` instead of `STR`.

<hr>

Information on 1.x versions has been gleaned from announcements by Eric P. Scott on comp.sys.next.announce.

### Version 1.3.1 - Released 1994-04-23

* Built fat (m68k+i486).
* There are no functional changes from the previous release.

### Version 1.3 - Released 1993-07-20

* Runs on Motorola processors using NeXTSTEP 2.1-2.2a, NeXTSTEP 3.0, or 3.1.

### Version 1.2 - Released 1992-10-15

* Works under 3.0 (for which the executable got 50% bigger, sigh)
* Lets you dump selected classes matching a regular expression, so you no longer need to wade through pages and pages of output when you’re looking for something specific.

### Version 1.1? - Released 199?-??-??

* The Google archives don’t go back this far. Was there ever a version 1.1 released? When? Any other info on it?

### Version 1.0 - Released 199?-??-??

* Was this the original release, or were there any before this? When was it released?
