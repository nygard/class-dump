iOS Class Guard
=========

iOS-Class-Guard is a command-line utility for obfuscating Objective-C class and protocol names. It was made as an extesion for [class-dump](https://github.com/nygard/class-dump). The utility generates symbol table which is then include during compilation. Effectively hides most of class, protocols, methods, properties and i-var names.

**iOS Class Guard will not enhance the security of your application, but will make it a harder to read. Obfuscation technique presented here will generate results similar to that produced by [ProGuard](http://proguard.sourceforge.net/).**

Version
-----------
0.5

Do I need It?
-----------
This utility makes code analyzing and runtime inspection more difficult. Which can be referred as simple/basic method of obfuscation. You may ask yourself why is it needed? Due to Objective-C architecture any dissection of iOS applications is rather simple. You may want to check out a following links:

* http://www.infointox.net/?p=123
* http://www.cycript.org/
* http://resources.infosecinstitute.com/ios-application-security-part-2-getting-class-information-of-ios-apps/
* http://timourrashed.com/decrypting-ios-app/

How it works?
----------
Utility works on compiled version of application. It reads Objective-C portion of Mach-O object files. Parses all classes, properties, methods and i-vars defined in that file adding all symbols to the list. Then it reads all dependent frameworks doing the same (parsing Objective-C code structure), but now adding symbols to forbidden list. Than all symbols from your executable that aren't in forbidden list are obfuscated. For each symbol random identifier consisting of letters and digits is generated. Every time you do obfuscation unique symbol map is generated. Generated map is then formatted as header file with C-preprocessor defines. File is then included in .pch file. During compilation any symbol defined in header is compiled with different identifier, the generated one.

Example generated symbols header:
``` C
// Properties
#ifndef _parentCell
#define _parentCell _m5c
#endif // _parentCell
#ifndef parentCell
#define parentCell m5c
#endif // parentCell
#ifndef setParentCell
#define setParentCell setM5c
#endif // setParentCell
#ifndef _buttonIndex
#define _buttonIndex _f8q
```

Installation
-----------
Execute this simple bash script in Terminal. When asked for password, enter your account. It's needed, because utility is installed in /usr/local/bin.

```sh
curl https://raw.githubusercontent.com/Polidea/ios-class-guard/master/install.sh | bash
```

How to use it?
-----------
A few steps is required to integrate iOS Class Guard in project.

1. To any used .PCH (Precompiled header) at top paste:
``` C
#ifndef DEBUG
#include "symbols.h"
#endif // DBEUG
```

2. Create empty ```symbols.h``` and add it to project.

3. Create ```generate_symbols_map``` and update project path, scheme and configuration name:

        #!/bin/bash
        set -xe
    
      # remove the content of symbols.h before compilation
      echo '' > SWTableViewCell/symbols.h 
    
      # Compile iOS xcarchive without obfuscation
      xcodebuild \
        -sdk iphoneos7.1 \
        -project SWTableViewCell.xcodeproj \
        -scheme SWTableViewCell \
        -configuration Release \
        -archivePath SWTableViewCell-no-obfuscated \
        clean archive
    
      # Generate symbols map and write it to SWTableViewCell/symbols.h
      ios-class-guard \
        --sdk-ios 7.1 \
        SWTableViewCell-no-obfuscated.xcarchive/Products/Applications/SWTableViewCell.app/SWTableViewCell > SWTableViewCell/symbols.h

4. Do ```bash generate_symbols_map``` everytime when you want to regenerate symbols map. It should be done every release.

5. The presented way is the simplest one. You can also add additional target that will automatically regenerate symbols map during compilation.

Example
-----------
You can take a look what changes are required and how it works in some example project.

``` sh
git clone https://github.com/Polidea/ios-class-guard-example ios-class-guard-example
cd ios-class-guard-example
make compile
```

Here is *class-dump* for non-obfuscated sources: 
https://github.com/Polidea/ios-class-guard-example/tree/master/SWTableViewCell-no-obfuscated.xcarchive/Headers

How it will look when you use *iOS Class Guard*:
https://github.com/Polidea/ios-class-guard-example/tree/master/SWTableViewCell-obfuscated.xcarchive/Headers

Command Line Options
-----------
```
ios-class-guard 0.5 (64 bit)
Usage: ios-class-guard [options] <mach-o-file>

  where options are:
        -F <class>     specify class filter for symbols obfuscator (also protocol))
        -i <symbol>    ignore obfuscation of specific symbol)
        --arch <arch>  choose a specific architecture from a universal binary (ppc, ppc64, i386, x86_64, armv6, armv7, armv7s, arm64)
        --list-arches  list the arches in the file, then exit
        --sdk-ios      specify iOS SDK version (will look for /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS<version>.sdk
                       or /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS<version>.sdk)
        --sdk-mac      specify Mac OS X version (will look for /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX<version>.sdk
                       or /Developer/SDKs/MacOSX<version>.sdk)
        --sdk-root     specify the full SDK root path (or use --sdk-ios/--sdk-mac for a shortcut)
```

Utility mostly requires you to get familiar with at least two options.

### Class filter
iOS Class Guard allows to filter out some of the class that can't be obfuscated. For example, because you use it as a precompiled static library.

iOS Code Style assumes that every class is prefixed with two-or-three-symbol identifier - namespace (ie. NS* for Foundation class). This allows you to filter in or filter out the whole namespace.

#### Example
```
-F '!APH*' -F '!MC*'
```

This will filter out any class in namespace *APH* and *MC*.

### Ignored symbols
It may happen that some symbols gets obfuscated when it shouldn't. For example you use C method and name Objective-C method using the same name. It will lead to linker error (*unresolved external*). You have to find what symbol is it and add it to list of ignored symbols.

#### Example
```
-i 'deflate' -i 'curl_*'
```
This will not obfuscate symbols of name *deflate* and symbols that starts with *curl_\**.

Limitations
-----------

Due to the way iOS Class Guard you should be aware of two main limitations with that approach.

### XIB and Storyboards
*ios-class-guard* is not aware of any *XIB* and *Storyboard* files, so any property and class name defined in these files most likely will be obfuscated and it will render *XIB* and *Storyboard* files broken. For now I suggest you to simply ignore these classes with *Class filter* (ie. ```-F '!MyNS*Controller```).


### Key-Value Observing (KVO)
It is possible that during obfuscation KVO will stop working. Most developers to specify *KeyPath* use hardcoded strings.

``` objc
- (void)registerObserver {
    [self.otherObject addObserver:self
                       forKeyPath:@"isFinished"
                          options:NSKeyValueObservingOptionNew
                          context:nil];
}

- (void)unregisterObserver {
    [otherObject removeObserver:self
                     forKeyPath:@"isFinished"
                        context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
              ofObject:(id)object
                change:(NSDictionary *)change
               context:(void *)context
{
  if ([keyPath isEqualToString:@"isFinished"]) {
    // ...
  }
}
```

This will simply not work. The property *isFinished* will get a new name and hardcoded string will not reflect the change.

Remove any *keyPath* and change it to ```NSStringFromSelector(@selector(keyPath))```.

**The fixed code should look like this:**

``` objc
- (void)registerObserver {
    [self.otherObject addObserver:self
                       forKeyPath:NSStringFromSelector(@selector(isFinished))
                          options:NSKeyValueObservingOptionNew
                          context:nil];
}

- (void)unregisterObserver {
    [otherObject removeObserver:self
                     forKeyPath:NSStringFromSelector(@selector(isFinished))
                        context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
              ofObject:(id)object
                change:(NSDictionary *)change
               context:(void *)context
{
  if ([keyPath isEqualToString:NSStringFromSelector(@selector(isFinished))]) {
    // ...
  }
}
```

License
----
TBD - MIT
