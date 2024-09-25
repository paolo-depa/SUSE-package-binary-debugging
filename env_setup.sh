#!/bin/bash

PACKAGE_NAME="wicked"
PACKAGE_VERSION="0.6.75-3.40.1" # Empty string for the latest version

DEBUGINFOD_SERVER="debuginfod.suse.cz:8002" # only available for 15-SPX

SOURCE_PATH="/usr/src/packages/SOURCES"
if [ ! -d $SOURCE_PATH ]; then
    echo "Source path $SOURCE_PATH does not exist"
#    exit 1
fi

cd $SOURCE_PATH

source /etc/os-release
OS_VERSION=$VERSION
if [[ $OS_VERSION == "12-SP5" ]]; then
    DEBUGINFO_POOL_REPO="SLES$OS_VERSION-Debuginfo-Pool"
    DEBUGINFO_UPDATE_REPO="SLES$OS_VERSION-Debuginfo-Updates"
    PATTERN_DEVEL="Basis-Devel"
    ADDITIONAL_PACKAGES=""
elif [[ $OS_VERSION =~ ^15 ]]; then
    DEBUGINFO_POOL_REPO="SLE-Module-Basesystem$OS_VERSION-Debuginfo-Pool"
    DEBUGINFO_UPDATE_REPO="SLE-Module-Basesystem$OS_VERSION-Debuginfo-Updates"
    PATTERN_DEVEL="devel_C_C++"
    ADDITIONAL_PACKAGES="gdb"

    # Activating the development tools module - cannot use jq here
    DEVTOOLS_ACTIVATE=`SUSEConnect -l | egrep "Activate with:.*development-tools" | cut -f 2 -d':'`
    if [[ ! -z $DEVTOOLS_ACTIVATE ]]; then
        $DEVTOOLS_ACTIVATE
    fi

    # Activating DEBUGINFOD support - only available on 15SPX
    echo "set debuginfod enabled on" > /root/.gdbinit
    echo "set debuginfod urls $DEBUGINFOD_SERVER" >> /root/.gdbinit

else
    echo "Unsupported OS version: $OS_VERSION"
    exit 1
fi


zypper mr -e $DEBUGINFO_POOL_REPO $DEBUGINFO_UPDATE_REPO
if [[ $? -ne 0 ]]; then
    echo "Failed to enable debuginfo repositories"
    exit 1
fi

# Install the Basis-Devel pattern (gdb included)
zypper install -y -t pattern $PATTERN_DEVEL

# Install debugging additional packages
if [[ ! -z $ADDITIONAL_PACKAGES ]]; then
    zypper in -y $ADDITIONAL_PACKAGES
fi

# Install the $PACKAGE_NAME package and its sources (which will be found in $SOURCE_PATH)
IS_OLD_PACKAGE="--oldpackage"
if [[ -z $PACKAGE_VERSION ]]; then
    IS_OLD_PACKAGE=""
fi

zypper in -y $IS_OLD_PACKAGE $PACKAGE_NAME=$PACKAGE_VERSION $PACKAGE_NAME-debuginfo=$PACKAGE_VERSION
zypper in -y -t srcpackage $IS_OLD_PACKAGE $PACKAGE_NAME=$PACKAGE_VERSION


SHORT_VERSION=${PACKAGE_VERSION%%-*}
SOURCE_TARFILE=$PACKAGE_NAME-$SHORT_VERSION.tar.bz2
if [[ ! -f $SOURCE_TARFILE ]]; then
    echo "Source tarfile $SOURCE_TARFILE does not exist"
    exit 1
fi
tar xjf $SOURCE_TARFILE > /dev/null

SOURCE_DIR=$PACKAGE_NAME-$SHORT_VERSION
if [[ ! -d $SOURCE_DIR ]]; then
    echo "Source directory $SOURCE_DIR does not exist"
    exit 1
fi

# In case of multiple sources in #SOURCE_DIR, it will be hard to understand which patch belongs to which source
# So, let's move the patches to the source directory and try to apply them on a best effort basis
mv *.patch $SOURCE_DIR
cd $SOURCE_DIR

for PATCH in `ls *.patch`; do
    patch -p1 < $PATCH
    if [[ $? -ne 0 ]]; then
        echo "Failed to apply patch $PATCH"
    fi
done