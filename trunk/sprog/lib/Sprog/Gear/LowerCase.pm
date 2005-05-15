package Sprog::Gear::LowerCase;

=begin sprog-gear-metadata

  title: Lowercase
  type_in: P
  type_out: P
  no_properties: 1

=end sprog-gear-metadata

=cut

use strict;

use base qw(Sprog::Gear);

sub data {
  my($self, $data) = @_;

  $self->msg_out(data => lc($data));
}

1;

__END__


=head1 NAME

Sprog::Gear::LowerCase - convert text to lowercase

=head1 DESCRIPTION

Any text passed through this gear will be converted to lowercase.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 



=begin :sprog-help-text

=head1 Lowercase Gear

This gear converts all text passed through it, to lowercase.  Both input and
output use 'pipe' connectors.

=head2 Properties

The Lowercase gear has no properties.

=end :sprog-help-text

