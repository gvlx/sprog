package Sprog::Gear::UpperCase;

use strict;

use base qw(Sprog::Gear);


sub title { 'Uppercase'; };

sub no_properties { 1;}

sub data {
  my($self, $data) = @_;

  $self->msg_out(data => uc($data));
}

1;
