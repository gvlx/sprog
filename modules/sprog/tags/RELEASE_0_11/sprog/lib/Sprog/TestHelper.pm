package Sprog::TestHelper;

use Test::More;
use Carp;

use File::Spec;
use lib File::Spec->catdir('t', 'lib');

sub import {
  my $class = shift;

  my %opt = ( @_ );

  plan skip_all => $opt{skip_all} if $opt{skip_all};

  if($opt{display}) {
    if(!defined($ENV{DISPLAY})  or  !$ENV{DISPLAY} =~ /:\d/) {
      plan 'skip_all' => 'display needed'
    }
  }

  if(my $req = $opt{requires}) {
    $req = [ $req ] unless ref $req;
    foreach my $pkg (@$req) {
      eval "use $pkg";
      plan 'skip_all' => "$pkg not installed" if $@;
    }
  }

  $opt{tests} ||= -1;
  if($opt{tests} < 0) {
    plan 'no_plan';
  }
  else {
    plan tests => $opt{tests};
  }

}


##############################################################################
# Switch back to the test script's namespace
##############################################################################

package main;

use Test::More;  # imports subs etc into caller

use strict;      # this is file-scoped so it doesn't affect the caller :-(
$^W = 1;         # brutal but effective

use Sprog::ClassFactory;  # everyone needs this

1;

=head1 NAME

Sprog::TestHelper - used by scripts in the Sprog test suite

=head1 DESCRIPTION

This module contains common code used by scripts in the test suite.  It is only
used during 'make test' and does not need to be installed as part the Sprog
installation - although it will do no harm if it is.

=head1 AUTHOR

This module was adapted by Grant McLean E<lt>grantm@cpan.orgE<gt> from the
TestHelper.pm module in the Gtk2-Perl distribution.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut



