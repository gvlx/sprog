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

__END__


=head1 NAME

Sprog::Gear::Lowercase - convert text to lowercase

=head1 DESCRIPTION

Any text passed through this gear will be converted to lower case.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=head1 HELP VIEWER TEXT

=for sprog-help-text

=head1 Lowercase File Gear

This gear converts all text passed through it, to lowercase.  Both input and
output use 'pipe' connectors.

=head2 Properties

The Lowercase gear has no properties.

