package Sprog::Gear::XSLT;

use strict;

use base qw(Sprog::Gear);

sub title { 'XSLT Transform' };

sub input_type    { 'X'; }
sub output_type   { 'X'; }

sub prime {
  my $self = shift;
  $self->app->alert(__PACKAGE__ . ' not yet implemented');
  return;
}

1;
