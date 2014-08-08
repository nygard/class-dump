iOS Class Guard
=========

iOS-Class-Guard is a command-line utility for obfuscating Objective-C class, protocol, property and method names. It was made as an extension for [class-dump](https://github.com/nygard/class-dump). The utility generates symbol table which is then include during compilation. Effectively hides most of class, protocols, methods, properties and i-var names.

**iOS Class Guard will not enhance the security of your application, but will make it a harder to read. Obfuscation technique presented here will generate results similar to that produced by [ProGuard](http://proguard.sourceforge.net/).**

Version
-----------
0.6

Do I need It?
-----------
This utility makes code analyzing and runtime inspection more difficult. Which can be referred as simple/basic method of obfuscation. You may ask yourself why is it needed? Due to Objective-C architecture any dissection of iOS applications is rather simple. You may want to check out a following links:

* http://www.infointox.net/?p=123
* http://www.cycript.org/
* http://resources.infosecinstitute.com/ios-application-security-part-2-getting-class-information-of-ios-apps/
* http://timourrashed.com/decrypting-ios-app/

How does it work?
----------
Utility works on compiled version of an application. It reads Objective-C portion of Mach-O object files. Parses all classes, properties, methods and i-vars defined in that file adding all symbols to the list. Then it reads all dependent frameworks doing the same (parsing Objective-C code structure), but now adding symbols to forbidden list. Then all symbols from your executable that aren't in forbidden list are obfuscated. For each symbol random identifier consisting of letters and digits is generated. Every time you do obfuscation unique symbol map is generated. Generated map is then formatted as header file with C-preprocessor defines. This file is then included in .pch file. Then it finds all XIBs and Storyboards and updates names inside (so effectively Interface Builder files are also obfuscated). Utility also finds xcdatamodel files inside your project and adds symbols (class and property names) to forbidden list. During compilation any symbol defined in header is compiled with different identifier, the generated one.

iOS Class Guard also provides support for obfuscating CocoaPods libraries. When you provide path to Pods project utility automatically goes through all listed targets and finds .xcconfig files and precompiled header paths which will be modified. Then it adds previously generated header to library .pch header and updates header search path in .xcconfig file for a target.

iOS Class Guard also generates symbol mapping in a JSON format. It’s needed for reversing the process when e.g. you get a crash report. Important note is that iOS Class Guard does not obfuscate system symbols, so if some of the methods/properties has same name in a custom class they won’t be obfuscated.

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
        SWTableViewCell-no-obfuscated.xcarchive/Products/Applications/SWTableViewCell.app/SWTableViewCell -O SWTableViewCell/symbols.h

4. Do ```bash generate_symbols_map``` every time when you want to regenerate symbols map. It should be done every release. Store symbols mapping json file so you can get real symbol names in case of a crash.

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
ios-class-guard 0.6 (64 bit)
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
        -X <directory> base directory for XIB, storyboards (will be searched recursively)
        -P <path>      path to project.pbxproj of Pods project (located inside Pods.xcodeproj)
        -O <path>      path to file where obfuscated symbols are written
        -m <path>      path to symbol file map (default value symbols.json)
        -c <path>      path to symbolicated crash dump
```

Utility mostly requires you to get familiar with few options.

### Output header path
iOS Class Guard requires you to provide path to generated symbols header.

#### Example
```
-O SWTableView\symbols.h
```

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

### CocoaPods
If you’re using CocoaPods in your project you can also obfuscate symbols inside external libraries. The only thing you need to specify path to Pods PBX project file. It’s located inside .xcodeproj directory. Utility will modify configurations and precompiled headers so that they’re also obfuscated.

#### Example
```
-P Pods/Pods.xcodeproj/project.pbxproj
```

### Other options

#### Xib directory
This is optional argument. By default utility is searching for all XIB/Storyboard files recursively from directory of execution (in most cases root directory of project). If you store those files in a different directory you can provide a path to directory where they can be found.

##### Example
```
-X SWTableView\Xib
```

#### Symbol mapping file
You can provide path where utility will save symbol mapping. By default it’s symbols.json.

#####
```
-m release/symbols_1.0.0.json
```

#### Reversing obfuscation in crash dump
iOS Class Guard lets you reverse the process of obfuscation. It might come handy when you get a crash report from user and you’re trying to find the reason. You can provide a path to file with crash dump or file with output of ```atos``` command. Symbols in the file which was provided will replaced using symbol mapping file. Result will be saved in the same file.

##### Example
```
-c crashdump -m symbols_1.0.0.json
```

Limitations
-----------

Due to the way iOS Class Guard you should be aware of two main limitations with that approach.

### XIB and Storyboards
*ios-class-guard* works pretty well with XIB and Storyboard files, but if you’re using external library which provide their bundle with Interface Builder files be sure to ignore those symbols as they won’t work when you launch the app and try to use them. You can do that using *Class filter*.

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
This file is part of ios-class-guard, a utility for obfuscating the Objective-C applications. Copyright (C) 2014 Polidea.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
