#!/bin/sh

ttree -f .ttreerc

if xmllint --noout --valid `find docroot -name '*.html' `
then
  echo "All HTML validated successfully"
fi


