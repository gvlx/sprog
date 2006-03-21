#!/bin/sh
#
# Use 'ttree' utility from the Perl Template Toolkit distribution to create
# web site under 'docroot' directory from templates under 'html'.
#

cd `dirname $0`

ttree -f .ttreerc

if xmllint --noout --valid `find docroot -name '*.html' `
then
  echo "All HTML validated successfully"
fi


