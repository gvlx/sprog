#!/bin/sh
#
# This script re-creates the apt-root APT repository.
#
# It assumes that the latest Sprog tarball is in the current directory.
#

TMP_DIR=deb-tmp
APT_DIR=apt-root

OVERRIDES=$HOME/.dh-make-perl/overrides
grep dh-make-perl-overrides $OVERRIDES >/dev/null 2>&1
if [ $? != 0 ]
then
  CWD=`pwd`
  echo "Error: You must add this line to $OVERRIDES:"
  echo "  do '$CWD/dh-make-perl-overrides';"
  exit 1
fi

SRC_PKG=`ls Sprog-*.tar.gz 2>/dev/null | sort | tail -1`
if [ -z "$SRC_PKG" ]
then
  echo "Cannot find ./Sprog-*.tar.gz"
  exit 1
fi
echo "Using $SRC_PKG"

VERSION=`echo $SRC_PKG | sed 's/Sprog-\(.*\)\.tar\.gz/\1/'`
echo "Package version is: $VERSION"


rm -rf $TMP_DIR
mkdir $TMP_DIR
cd $TMP_DIR

tar xvfz ../Sprog-0.05.tar.gz

export DEBFULLNAME="Grant McLean"
export DEBEMAIL="grantm@cpan.org"
dh-make-perl --build Sprog-0.05

cd ..
rm -rf $APT_DIR
CONTRIB_DIR=$APT_DIR/dists/unstable/contrib
for ARCH in i386 amd64 all
do
  ARCH_DIR=$CONTRIB_DIR/binary-$ARCH
  mkdir -p $ARCH_DIR
  cp $TMP_DIR/libsprog-perl_$VERSION-1_all.deb $ARCH_DIR
  pushd $APT_DIR/dists/unstable
  dpkg-scanpackages contrib/binary-$ARCH ../../../dpkg-scanpackages-overrides \
    | gzip > contrib/binary-$ARCH/Packages.gz
  popd
done
