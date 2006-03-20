package Sprog::Gear::XMLWriter;

use strict;

use base qw(Sprog::Gear);

sub title { 'Write XML' };

sub input_type    { 'X'; }
sub output_type   { 'P'; }

sub prime {
  my $self = shift;
  $self->app->alert(__PACKAGE__ . ' not yet implemented');
  return;
}

1;
