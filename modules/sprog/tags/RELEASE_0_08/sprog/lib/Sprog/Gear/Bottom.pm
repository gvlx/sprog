package Sprog::Gear::Bottom;

use strict;

use base qw(Sprog::Gear);

sub output_type { undef; }

1;

=head1 NAME

Sprog::Gear::Bottom - a base class for output gears

=head1 SYNOPSIS

  use base qw(Sprog::Gear::Bottom);

=head1 DESCRIPTION

This class is intended to be used as a base class for output gears - ie:
gears which come at the bottom of the machine.


=head1 METHODS

=head2 output_type

Defines the output connector type as C<undef>.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut


