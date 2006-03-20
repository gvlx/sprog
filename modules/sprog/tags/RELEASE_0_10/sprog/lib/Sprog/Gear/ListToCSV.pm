package Sprog::Gear::ListToCSV;

=begin sprog-gear-metadata

  title: List to CSV
  type_in: A
  type_out: P
  no_properties: 1

=end sprog-gear-metadata

=cut

use strict;

use base qw(Sprog::Gear);

sub row {
  my($self, $r) = @_;

  my @f = map {
    s/"/""/g;
    /[,"\n\t]/ ? qq("$_") : $_;
  } @$r;

  $self->msg_out(data => join(',', @f) . "\n");
}

1;

__END__


=head1 NAME

Sprog::Gear::ListToCSV - converts data to CSV

=head1 DESCRIPTION

Takes rows of field values and converts them to lines of CSV data.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 List to CSV Gear

This gear takes rows of input data from the 'list' connector and writes lines
of data in CSV (comma-separated values) format out the 'pipe' connector.

=head2 Properties

This gear has no properties.

=end :sprog-help-text
