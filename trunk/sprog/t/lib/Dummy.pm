package Dummy;

use strict;
use warnings;

use Scalar::Util qw(weaken);


sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;

  $self->{app} && weaken($self->{app});

  return $self;
}


sub apply_prefs { return; }


1;

