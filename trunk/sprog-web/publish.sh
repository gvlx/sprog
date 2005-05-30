#!/bin/sh

cd html

echo "Building archive"
tar cfj /tmp/sprog-web.tbz --exclude=CVS --exclude=.cvsignore --exclude=.*.swp .

echo "Uploading to SourceForge"
ssh grantm@shell.sourceforge.net sh -c \
  "'cd /home/groups/s/sp/sprog/htdocs/; tar xvfj -'" < /tmp/sprog-web.tbz

rm -f /tmp/sprog-web.tbz

echo "wget -C off -O - http://sprog.sourceforge.net/debian/dists/unstable/contrib/binary-i386/Packages.gz | gunzip | grep ^Version"

wget -C off -O - http://sprog.sourceforge.net/debian/dists/unstable/contrib/binary-i386/Packages.gz | gunzip | grep ^Version
