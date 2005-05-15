package Sprog::Gear::UpperCase;

=begin sprog-gear-metadata

  title: Uppercase
  type_in: P
  type_out: P

=end sprog-gear-metadata

=cut

use strict;

use base qw(Sprog::Gear);


sub title { 'Uppercase'; };

sub no_properties { 1;}

sub data {
  my($self, $data) = @_;

  $self->msg_out(data => uc($data));
}

1;

__END__


=head1 NAME

Sprog::Gear::UpperCase - convert text to uppercase

=head1 DESCRIPTION

Any text passed through this gear will be converted to uppercase.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Uppercase Gear

This gear converts all text passed through it, to uppercase.  Both input and
output use 'pipe' connectors.

=head2 Properties

The Uppercase gear has no properties.

=end :sprog-help-text
