package Sprog::Gear::Top;

use strict;

use base qw(Sprog::Gear);

sub input_type { undef; }

sub msg_queue { die __PACKAGE__ . " has no input queue\n"; }

1;

=head1 NAME

Sprog::Gear::Top - a base class for data source gears

=head1 SYNOPSIS

  use base qw(Sprog::Gear::Top);

=head1 DESCRIPTION

This class is intended to be used as a base class for data source gears - ie:
gears without an input connector.


=head1 METHODS

=head2 input_type

Defines the input connector type as C<undef>.

=head2 msg_queue ( )

Throws a fatal exception if an attempt is made to access the input queue -
sincethis type of gear doesn't have one.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut


