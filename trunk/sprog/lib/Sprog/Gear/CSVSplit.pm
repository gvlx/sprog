package Sprog::Gear::CSVSplit;

use strict;

use base qw(Sprog::Gear);

sub title { 'CSV Split' };

sub output_type   { 'A'; }

sub prime {
  my $self = shift;
  $self->app->alert(__PACKAGE__ . ' not yet implemented');
  return;
}

1;
