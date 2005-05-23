package Sprog::Gear::CSVSplit;

=begin sprog-gear-metadata

  title: CSV Split
  type_in: P
  type_out: A
  no_properties: 1

=end sprog-gear-metadata

=cut

use strict;
use warnings;

use base qw(
  Sprog::Gear::InputByLine
  Sprog::Gear
);


sub line {
  my($self, $line) = @_;

  chomp $line;
  my @a = split /,/, $line;

  $self->msg_out(list => \@a);
}

1;

__END__


=head1 NAME

Sprog::Gear::CSVSplit - a naive CSV parser

=head1 DESCRIPTION

This is a I<very> naive CSV parser that takes each line from the input
connector and generates a 'list' event on the output connector.  It doesn't
handle quoting, escaping or embedded newlines.  It will be replaced with a
more capable version soon.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 CSV Split Gear

I<Warning: this is just a proof-of-concept implementation.>

This gear takes lines of comma separated fields from the 'pipe' input
connector, splits them and sends rows of field values out the 'list' output
connector.

Unfortunately, the current implementation is not industrial strength.  It
can't handle the quoting, escaping and embedded newlines that occur in many
real CSV files.  A more robust implementation will replace this one soon.

=head2 Properties

This gear has no properties.

=end :sprog-help-text

