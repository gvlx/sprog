package Sprog::Gear::XMLToSAX;

use strict;

use base qw(Sprog::Gear);

sub title { 'Parse XML' };

sub output_type   { 'X'; }

sub prime {
  my $self = shift;
  $self->app->alert(__PACKAGE__ . ' not yet implemented');
  return;
}

1;
