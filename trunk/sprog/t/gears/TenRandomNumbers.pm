package TenRandomNumbers;

=begin sprog-gear-metadata

  title: Ten Random Numbers
  type_in: _
  type_out: P
  keywords: monkey butter
  no_properties: 1
  custom_command_gear: 1

=end sprog-gear-metadata

=cut

use strict;

use base qw(Sprog::Gear::CommandIn);

__PACKAGE__->declare_properties( -command => undef );

sub command { q(perl -le 'print int(rand(100)) foreach(1..10)'); }

1;
