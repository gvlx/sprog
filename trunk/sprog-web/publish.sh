#!/bin/sh

#cd html
#
#echo "Building archive"
#tar cfj /tmp/sprog-web.tbz --exclude=CVS --exclude=.cvsignore --exclude=nav.html --exclude=.*.swp .
#
#echo "Uploading to SourceForge"
#ssh grantm@shell.sourceforge.net sh -c \
#  "'cd /home/groups/s/sp/sprog/htdocs/; tar xvfj -'" < /tmp/sprog-web.tbz
#
#rm -f /tmp/sprog-web.tbz

echo "Uploading to SourceForge"

RSYNCOPTS="--verbose --recursive --compress --checksum --links --perms --times --delete --delete-after --delay-updates --itemize-changes"

rsync $RSYNCOPTS ./docroot/. grantm@shell.sourceforge.net:/home/groups/s/sp/sprog/htdocs/

echo "wget -q --no-cache -O - http://sprog.sourceforge.net/debian/dists/unstable/contrib/binary-i386/Packages.gz | gunzip | grep ^Version"

wget -q --no-cache -O - http://sprog.sourceforge.net/debian/dists/unstable/contrib/binary-i386/Packages.gz | gunzip | grep ^Version
