package Pstax::Gear::LowerCase;

use strict;

use base qw(Pstax::Gear);


sub no_properties { 1;}

sub title { 'Lowercase' };

sub line {
  my($self, $line) = @_;

  $self->msg_out(line  => lc($line));
}

1;
