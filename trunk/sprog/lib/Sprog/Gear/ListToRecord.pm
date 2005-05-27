package Sprog::Gear::ListToRecord;

=begin sprog-gear-metadata

  title: List To Record
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
    $self->{_keys} = [ @$row ];
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

=head1 List To Record Gear

This gear converts rows of data into records.  It assumes the first row
contains column headings and uses the values as field names.  Input comes from
a 'list' connector and output goes to a 'record' connector.

=head2 Properties

This gear has no properties.

=end :sprog-help-text
