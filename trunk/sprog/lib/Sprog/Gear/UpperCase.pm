package Sprog::Gear::UpperCase;

use strict;

use base qw(Sprog::Gear);


sub title { 'Uppercase'; };

sub no_properties { 1;}

sub line {
  my($self, $line) = @_;

  $self->msg_out(line  => uc($line));
}

1;
