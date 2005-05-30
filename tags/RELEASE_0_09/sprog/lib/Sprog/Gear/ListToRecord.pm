package Sprog::Gear::ListToRecord;

=begin sprog-gear-metadata

  title: List to Record
  type_in: A
  type_out: H
  no_properties: 1

=end sprog-gear-metadata

=cut

use strict;
use warnings;

use base qw(Sprog::Gear);

sub engage {
  my $self = shift;

  delete $self->{_keys};

  return $self->SUPER::engage;
}


sub row {
  my($self, $row) = @_;

  if($self->{_keys}) {
    my %rec;
    @rec{ @{$self->{_keys}} } = @$row;
    $self->msg_out(record => \%rec);
  }
  else {
    $self->{_keys} = [ map { s/\W+/_/gs; lc($_) } @$row ];
  }
}

1;

__END__


=head1 NAME

Sprog::Gear::ListToRecord - convert rows to records using column headings

=head1 DESCRIPTION

Converts each received row into a record, using the field values in the first
row received as field names (hash keys).

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 List to Record Gear

This gear converts rows of data into records.  It assumes the first row
contains column headings and uses the values as field names.  Input comes from
a 'list' connector and output goes to a 'record' connector.

The values in the first row undergo some cleanup before they're used as field
names.  Firstly, all the letters are converted to lowercase, and then any
non-alphanumeric characters are converted to a single underscore ('_').  Here
are some examples to show you what to expect:

  Column Heading     Field Name      Comment
  ================   =============   ==========================
  Surname            surname         converted to lower case
  First Name         first_name      space converted to _
  House & Street     house_street    ' & ' converted to _

=head2 Properties

This gear has no properties.

=end :sprog-help-text
