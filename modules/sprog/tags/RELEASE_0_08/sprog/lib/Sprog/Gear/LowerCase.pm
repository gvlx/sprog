package Sprog::Gear::LowerCase;

use strict;

use base qw(Sprog::Gear);


sub no_properties { 1;}

sub title { 'Lowercase' };

sub data {
  my($self, $data) = @_;

  $self->msg_out(data => lc($data));
}

1;
