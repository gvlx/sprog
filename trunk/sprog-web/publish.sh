#!/bin/sh

cd html

echo "Building archive"
tar cfj /tmp/sprog-web.tbz --exclude=CVS .

echo "Uploading to SourceForge"
ssh grantm@shell.sourceforge.net sh -c \
  "'cd /home/groups/s/sp/sprog/htdocs/; tar xvfj -'" < /tmp/sprog-web.tbz

rm -f /tmp/sprog-web.tbz
