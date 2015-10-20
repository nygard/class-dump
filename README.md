iOS Class Guard
=========

iOS-Class-Guard is a command-line utility for obfuscating Objective-C class, protocol, property and method names. It was made as an extension for [class-dump](https://github.com/nygard/class-dump). The utility generates a symbol table which is then included during compilation. It effectively hides most of class, protocol, method, property and i-var names.

**iOS Class Guard itself is not the silver bullet for security of your application. However, it will definitiely make your application harder to read by an attacker.**

Read the official announcement at [Polidea Blog](http://www.polidea.com/#!heartbeat/blog/Protecting_iOS_Applications)

if you need **iOS Class Guard Pro** with more features [click here](#pro-version).

Version
-----------
0.8

Do I need It?
-----------
This utility makes code analyzing and runtime inspection more difficult, which can be referred to as a simple/basic method of obfuscation. You may ask yourself why it is needed; due to Objective-C architecture any dissection of iOS applications is rather simple. You may want to check out the following links:

* http://www.infointox.net/?p=123
* http://www.cycript.org/
* http://resources.infosecinstitute.com/ios-application-security-part-2-getting-class-information-of-ios-apps/
* http://timourrashed.com/decrypting-ios-app/

How does it work?
----------
The utility works on the compiled version of an application. It reads the Objective-C portion of Mach-O object files. It parses all classes, properties, methods and i-vars defined in that file adding all symbols to the list. Then it reads all dependent frameworks doing the same (parsing Objective-C code structure), but now adding symbols to a forbidden list. Then all symbols from your executable that aren't in the forbidden list are obfuscated. For each symbol a random identifier consisting of letters and digits is generated. Every time you do obfuscation, a unique symbol map is generated. The generated map is then formatted as a header file with C-preprocessor defines. This file is then included in .pch file. Then it finds all XIBs and Storyboards and updates names inside (so effectively Interface Builder files are also obfuscated). The utility also finds xcdatamodel files inside your project and adds symbols (class and property names) to the forbidden list. During compilation any symbol defined in the header is compiled with a different identifier, the generated one.

iOS Class Guard also provides support for obfuscating CocoaPods libraries. When you provide paths to Pods the project utility automatically goes through all listed targets and finds .xcconfig files and precompiled header paths to be modified. Then it adds the previously generated header to library .pch header and updates the header search path in .xcconfig file for a target.

iOS Class Guard also generates symbol mapping in a JSON format. It’s needed for reversing the process when e.g. you get a crash report. It is important to note that iOS Class Guard does not obfuscate system symbols, so if some of the methods/properties have the same name in a custom class they won’t be obfuscated.

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
Execute this simple bash script in Terminal. When asked for the password, enter your account. It's needed, because the utility is installed in /usr/local/bin.

``` sh
brew install ios-class-guard
```

To install bleeding edge version:
``` sh
brew install --HEAD ios-class-guard
```

How to use it?
-----------
A few steps are required to integrate iOS Class Guard in a project.

1. Download ```obfuscate_project``` in to your project root path.

``` sh
curl -o obfuscate_project https://raw.githubusercontent.com/Polidea/ios-class-guard/master/contrib/obfuscate_project && chmod +x obfuscate_project
```

2. Update the project file, scheme and configuration name.

3. Do ```bash obfuscate_project``` every time when you want to obfuscate your project. It should be done every release. Store the json file containing symbol mapping so you can get the original symbol names in case of a crash.

4. Build, test and archive your project using Xcode or other tools.

The presented way is the simplest one. You can also add additional target that will automatically regenerate the symbols map during compilation.

Pre compiled header file
-----------
After obfuscation, iOS-Class-Guard will try to add generated symbols header (`symbols.h`) to your project's `*.pch` file. However, projects created in Xcode 6 and above don't contain `*.pch` file by default. In case your project doesnt have any `*.pch` file, you have to add it manually **before obfuscation**. 

To add `*.pch` file to your project follow the steps below:

1. Create `PCH` file in your project's root directory. In Xcode go to `File -> New -> File -> iOS -> Other -> PCH File`.
To ensure backward compatibility iOS-Class-Guard will be looking for a file matching the `*-Prefix.pch` mask, as an example `MyProject-Prefix.pch`


2. At the target's *Build Settings*, in *Apple LLVM - Language* section, set **Prefix Header** to your PCH file name.

3. At the target's *Build Settings*, in *Apple LLVM - Language* section, set **Precompile Prefix Header** to `YES`.


For more details please refer to [this](http://stackoverflow.com/a/24524692/1219382) Stack Overflow question.

Example
-----------
You can take a look what changes are required and how it works in some example projects.

``` sh
git clone https://github.com/Polidea/ios-class-guard-example ios-class-guard-example
cd ios-class-guard-example
make compile
```

Here is *class-dump* for non-obfuscated sources: 
https://github.com/Polidea/ios-class-guard-example/tree/master/SWTableViewCell-no-obfuscated.xcarchive/Headers

What it will look like when you use *iOS Class Guard*:
https://github.com/Polidea/ios-class-guard-example/tree/master/SWTableViewCell-obfuscated.xcarchive/Headers

Command Line Options
-----------
```
ios-class-guard 0.8 (64 bit)
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

The utility requires you to get familiar with a few options.

### Output header path
iOS Class Guard requires you to provide path to generated symbols header.

#### Example
```
-O SWTableView/symbols.h
```

### Class filter
iOS Class Guard allows to filter out some of the classes that can't be obfuscated. For example, because you use it as a precompiled static library.

iOS Code Style assumes that every class is prefixed with a two-or-three-symbol identifier - namespace (ie. NS* for Foundation class). This allows you to filter in or filter out the whole namespace.

#### Example
```
-F '!APH*' -F '!MC*'
```

This will filter out any class in namespace *APH* and *MC*.

### Ignored symbols
It may happen that some symbols get obfuscated even though they shouldn’t, e.g. if you use C method and name Objective-C method using the same name. It will lead to a linker error (*unresolved external*). You have to find what symbol is it and add it to the list of ignored symbols.

#### Example
```
-i 'deflate' -i 'curl_*'
```
This will not obfuscate symbols named *deflate* and symbols that start with *curl_\**.

### CocoaPods
If you’re using CocoaPods in your project you can also obfuscate symbols inside external libraries. The only thing you need is to specify path to Pods PBX project file. It’s located inside the .xcodeproj directory. Utility will modify configurations and precompiled headers so that they’re also obfuscated.

#### Example
```
-P Pods/Pods.xcodeproj/project.pbxproj
```

### Other options

#### Xib directory
This is optional argument. By default utility searches for all XIB/Storyboard files recursively from directory of execution (in most cases root directory of the project). If you store those files in a different directory you can provide a path to the directory where they can be found.

##### Example
```
-X SWTableView/Xib
```

#### Symbol mapping file
You can provide the path where utility will save symbol mapping. By default it’s symbols.json.

#####
```
-m release/symbols_1.0.0.json
```

#### Reversing obfuscation in crash dump
iOS Class Guard lets you reverse the process of obfuscation. It might come in handy when you get a crash report from a user and you’re trying to find the reason. You can provide a path to a file with crash dump or a file with the output of ```atos``` command. Symbols in the file which was provided will be replaced using the symbol mapping file. The result will be saved in the same file.

##### Example
```
-c crashdump -m symbols_1.0.0.json
```

#### Reversing obfuscation in dSYMs
iOS Class Guard lets you reverse the process of obfuscation for automatic crash reporting tools such as Crashlytics, Fabric, BugSense/Splunk Mint, Crittercism or HockeyApp. With ```--dsym``` parameter, iOS Class Guard will exchange obfuscated symbols with original ones within provided dSYM file. We highly recommend you adding in the very beginnig of your Build Phases/Run script one line shown in the example below to automate dSYM translation process. Feature has been tested with the tools mentioned above.

##### Build Phases/Run script example
```
if [ -f "$PROJECT_DIR/symbols.json" ]; then
/usr/local/bin/ios-class-guard -m $PROJECT_DIR/symbols.json --dsym $DWARF_DSYM_FOLDER_PATH/$DWARF_DSYM_FILE_NAME --dsym-out $DWARF_DSYM_FOLDER_PATH/$DWARF_DSYM_FILE_NAME
fi

# Another invocations eg.: ./Crashlytics.framework/run <Crashlytics secret #1> <Crashlytics secret #2>
```

##### Manual usage example
```
ios-class-guard -m symbols.json --dsym MyProject_obfuscated.app.dSYM --dsym-out MyProject_unobfuscated.app.dSYM
```

Limitations
-----------

Due to the way iOS Class Guard works you should be aware of two main limitations of that approach.

### XIB and Storyboards
*ios-class-guard* works pretty well with XIB and Storyboard files, but if you’re using external libraries which provide their bundle with Interface Builder files be sure to ignore those symbols, as they won’t work when you launch the app and try to use them. You can do that using *Class filter*.

### Key-Value Observing (KVO)
It is possible that during obfuscation KVO will stop working. Most developers use hardcoded strings to specify *KeyPath*.

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

This will simply not work. The property *isFinished* will get a new name and the hardcoded string will not reflect the change.

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

### Serialization
If you use classes that are saved to the disk or user defaults using `NSCoding` protocol you’ll have to exclude them from obfuscation. If you don’t, after generating symbols again your app will start crashing as it won’t be able to read that class from serialized data.

### Undefined symbols
When using `iOS-Class-Guard` it is more than probable that you will encounter issues similar to this:

```
Undefined symbols for architecture i386:
  "_OBJC_CLASS_$_n9z", referenced from:
      objc-class-ref in GRAppDelegate.o
```

To fix it, copy `n9z` and search for it in `symbols.h`. Most probably it will be a class. You simply have to exclude it from obfuscation by specifying: `-F '!UnresolvedClassName'` and retest.

Note
---
iOS-Class-Guard works alongside LLVM Obfuscator: https://github.com/obfuscator-llvm/obfuscator. However, this has not been tested.

Pro version
-----------

Contact us at [ios-class-guard@polidea.com](mailto:ios-class-guard@polidea.com) if you need iOS Class Guard Pro with more features including:
* Encryption of strings and constants
* Tamper detection mechanism
* Anti-debug mechanism
* Methods inlining
* Assets encryption
* Control flow obfuscation
* Code virtualization with encryption
* API method execution hiding

License
----
This file is part of ios-class-guard, a utility for obfuscating the Objective-C applications. Copyright (C) 2014 Polidea.
The application is made as an extension for class-dump, a utility for examining the Objective-C segment of Mach-O files. Copyright (C) 1997-1998, 2000-2001, 2004-2013 Steve Nygard.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
