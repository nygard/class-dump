#!/usr/bin/python

from datetime import *
from subprocess import *
import glob
import os
import sys

TESTDIR = "/tmp/cdt"
TESTDIR_OLD = TESTDIR + "/old"
TESTDIR_NEW = TESTDIR + "/new"
TESTDIR_NEW_32 = TESTDIR + "/new32"
TESTDIR_NEW_64 = TESTDIR + "/new64"

OLD_CD = "~/Unix/bin/class-dump-3.3.2"
#OLD_CD = "/bin/echo"
NEW_CD = "/Local/nygard/Products/Debug/class-dump"

# Must be a version that supports --list-arches
ARCH_CD = "/Local/nygard/Products/Debug/class-dump"

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
    "~/Applications/*.app",
    "/System/Library/CoreServices/*.app",
]

mac_bundles = [
    "/System/Library/CoreServices/*.bundle",
]

#mac_testapps = [
#    "/Volumes/BigData/TestApplications/*.app",
#]

#iphone_sdk_version = "3.2"
iphone_sdk_version = "4.0"
iphone_sdk_base = "/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS" + iphone_sdk_version + ".sdk"

iphone_frameworks = [
    iphone_sdk_base + "/System/Library/Frameworks/*.framework",
    iphone_sdk_base + "/System/Library/PrivateFrameworks/*.framework",
]
iphone_apps = []
iphone_bundles = []

OLD_OPTS = ""
NEW_OPTS = "--sdk-root " + iphone_sdk_version

print "Starting tests at", datetime.today().ctime()
print
print "Old class-dump:", " ".join(Popen("ls -al " + OLD_CD, shell=True, stdout=PIPE).stdout.readlines()),
print "New class-dump:", " ".join(Popen("ls -al " + NEW_CD, shell=True, stdout=PIPE).stdout.readlines()),

apps = []
frameworks = []
bundles = []

#sdict = dict(apps=mac_apps, frameworks=mac_frameworks, bundles=mac_bundles)
sdict = dict(apps=iphone_apps, frameworks=iphone_frameworks, bundles=iphone_bundles)

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

def mkdir_ignore(dir):
    try:
        os.mkdir(dir)
    except OSError as e:
        pass

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
    proc = Popen(ARCH_CD + " --list-arches " + path, shell=True, stdout=PIPE)
    arches = proc.stdout.readline().rstrip().split(" ")
    #print arches
    proc.stdout.readlines()
    for arch in arches:
        if arch == "none":
            out = open("%s/%s-%s.txt" % (TESTDIR_OLD, base, ext), "w");
            Popen("%s -s -t %s %s" % (OLD_CD, OLD_OPTS, path), shell=True, stdout=out, stderr=out)
            out.close()

            out = open("%s/%s-%s.txt" % (TESTDIR_NEW, base, ext), "w");
            Popen("%s -s -t %s %s" % (NEW_CD, NEW_OPTS, path), shell=True, stdout=out, stderr=out)
            out.close()
        else:
            print arch

            out = open("%s/%s-%s-%s.txt" % (TESTDIR_OLD, base, arch, ext), "w");
            Popen("%s -s -t %s --arch %s %s" % (OLD_CD, OLD_OPTS, arch, path), shell=True, stdout=out, stderr=out)
            out.close()

            out = open("%s/%s-%s-%s.txt" % (TESTDIR_NEW, base, arch, ext), "w");
            Popen("%s -s -t %s --arch %s %s" % (NEW_CD, NEW_OPTS, arch, path), shell=True, stdout=out, stderr=out)
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
