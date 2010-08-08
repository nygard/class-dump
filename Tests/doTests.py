#!/usr/bin/python

from datetime import *
from subprocess import *
import glob
import os
import sys
import getopt

TESTDIR = "/tmp/cdt"
TESTDIR_OLD = TESTDIR + "/old"
TESTDIR_NEW = TESTDIR + "/new"
TESTDIR_NEW_32 = TESTDIR + "/new32"
TESTDIR_NEW_64 = TESTDIR + "/new64"

OLD_CD = os.path.expanduser("~/Unix/bin/class-dump-3.3.2")
#OLD_CD = "/bin/echo"
NEW_CD = os.path.expanduser("/Local/nygard/Products/Debug/class-dump")

# Must be a version that supports --list-arches
ARCH_CD = os.path.expanduser("/Local/nygard/Products/Debug/class-dump")

mac_frameworks = [
    "/System/Library/Frameworks/*.framework",
    "/System/Library/PrivateFrameworks/*.framework",
    "/Developer/Library/Frameworks/*.framework",
    "/Developer/Library/PrivateFrameworks/*.framework",
]

mac_apps = [
    "/Applications/*.app",
    "/Applications/*/*.app",
    "/Applications/Utilities/*.app",
    "/Developer/Applications/*.app",
    "/Developer/Applications/*/*.app",
    "~/Applications/*.app",
    "/System/Library/CoreServices/*.app",
]

mac_bundles = [
    "/System/Library/CoreServices/*.bundle",
]

#mac_testapps = [
#    "/Volumes/BigData/TestApplications/*.app",
#]

def resolve_sdk_root_alias(sdk_root="4.0"):
    if sdk_root in ("3.2", "4.0", "4.1", ):
        return "/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS" + sdk_root + ".sdk"
    return sdk_root

def build_ios_paths(sdk_root):
    iphone_frameworks = [
        sdk_root + "/System/Library/Frameworks/*.framework",
        sdk_root + "/System/Library/PrivateFrameworks/*.framework",
        ]
    iphone_apps = []
    iphone_bundles = []
    return dict(apps=iphone_apps, frameworks=iphone_frameworks, bundles=iphone_bundles)

def mkdir_ignore(dir):
    try:
        os.mkdir(dir)
    except OSError as e:
        pass

def printUsage():
    print "doTests.py [--ios] [--sdk-root <path, 4.1, 4.0 or 3.2>]"
    print

def main(argv):
    try:
        opts, args = getopt.getopt(argv, "", ["sdk-root=", "ios"])
    except getopt.GetoptError:
        printUsage()
        sys.exit(2)

    shouldTestIOs = False
    sdk_root = None

    for opt, arg in opts:
        if opt in ("--ios",):
            shouldTestIOs = True
        if opt in ("--sdk-root",):
            sdk_root = arg

    sdk_root = resolve_sdk_root_alias(sdk_root)

    if shouldTestIOs:
        print "Testing on iOS targets"
        sdict = build_ios_paths(sdk_root)
        OLD_OPTS = []
        NEW_OPTS = ["--sdk-root", sdk_root]
    else:
        print "Testing on Mac OS X targets"
        if sdk_root:
            print "Ignoring --sdk-root for macosx testing"
        sdict = dict(apps=mac_apps, frameworks=mac_frameworks, bundles=mac_bundles)
        OLD_OPTS = []
        NEW_OPTS = []

    print "Starting tests at", datetime.today().ctime()
    print
    print "Old class-dump:", " ".join(Popen("ls -al " + OLD_CD, shell=True, stdout=PIPE).stdout.readlines()),
    print "New class-dump:", " ".join(Popen("ls -al " + NEW_CD, shell=True, stdout=PIPE).stdout.readlines()),

    apps = []
    frameworks = []
    bundles = []

    for pattern in sdict["apps"]:
        apps.extend(glob.glob(pattern))
    for pattern in sdict["frameworks"]:
        frameworks.extend(glob.glob(pattern))
    for pattern in sdict["bundles"]:
        bundles.extend(glob.glob(pattern))

    print "  Framework count:", len(frameworks)
    print "Application count:", len(apps)
    print "     Bundle count:", len(bundles)
    print "            Total:", len(frameworks) + len(apps) + len(bundles)

    mkdir_ignore(TESTDIR)
    mkdir_ignore(TESTDIR_OLD)
    mkdir_ignore(TESTDIR_NEW)

    all = []
    all.extend(frameworks)
    all.extend(apps)
    all.extend(bundles)

    for path in all:
        (base, ext) = os.path.splitext(os.path.basename(path))
        ext = ext.lstrip(".")
        print base, ext
        proc = Popen([ARCH_CD, "--list-arches", path], shell=False, stdout=PIPE)
        arches = proc.stdout.readline().rstrip().split(" ")
        print arches
        proc.stdout.readlines()
        for arch in arches:
            if arch == "none":
                command = [OLD_CD, "-s", "-t", path]
                command.extend(OLD_OPTS)
                #print command
                out = open("%s/%s-%s.txt" % (TESTDIR_OLD, base, ext), "w");
                Popen(command, shell=False, stdout=out, stderr=out)
                out.close()

                command = [NEW_CD, "-s", "-t", path]
                command.extend(NEW_OPTS)
                #print command
                out = open("%s/%s-%s.txt" % (TESTDIR_NEW, base, ext), "w");
                Popen(command, shell=False, stdout=out, stderr=out)
                out.close()
            else:
                print arch

                command = [OLD_CD, "-s", "-t", "--arch", arch, path]
                command.extend(OLD_OPTS)
                #print command
                out = open("%s/%s-%s-%s.txt" % (TESTDIR_OLD, base, arch, ext), "w");
                Popen(command, shell=False, stdout=out, stderr=out)
                out.close()

                command = [NEW_CD, "-s", "-t", "--arch", arch, path]
                command.extend(NEW_OPTS)
                #print command
                out = open("%s/%s-%s-%s.txt" % (TESTDIR_NEW, base, arch, ext), "w");
                Popen(command, shell=False, stdout=out, stderr=out)
                out.close()

    print "Ended tests at", datetime.today().ctime()
    Popen("opendiff %s %s" % (TESTDIR_OLD, TESTDIR_NEW), shell=True)

#----------------------------------------------------------------------
#
## arch = none check for FWAVCPrivate.framework, KAdminClient, Kernel, SyndicationUI
#
## We can remove files that don't contain Objective-C runtime information.
## Need to jump through some hoops because of the cursed spaces in filenames, grr.
#foreach i (/tmp/cdt/{old,new}/*.txt)
#    grep -q "This file does not contain" $i
#    if [ $? -eq 0 ]; then
#        rm $i
#    fi
#end
#
### Set up comparisons of new 32-bit vs. 64-bit output
##foreach arch (ppc ppc7400 i386) do
##    foreach i ($TESTDIR_NEW/*-$arch-*) do
##        ln -s $i $TESTDIR_NEW_32
##    done
##done
##
##foreach arch (ppc64 x86_64) do
##    foreach i ($TESTDIR_NEW/*-$arch-*) do
##        ln -s $i $TESTDIR_NEW_64
##    done
##done
#
#echo "Ended tests at `date`"
#opendiff /tmp/cdt/old /tmp/cdt/new
#

if __name__ == "__main__":
    main(sys.argv[1:])
