package Sprog::Gear::SelectColumns;

=begin sprog-gear-metadata

  title: Select Columns
  type_in: A
  type_out: A

=end sprog-gear-metadata

=cut

use strict;
use warnings;

use base qw(Sprog::Gear);

__PACKAGE__->declare_properties(
  columns => '',
  base => 1,
);


sub engage {
  my $self = shift;

  delete $self->{_colspec};
  local($_) = $self->columns;
  return $self->alert('You must select some columns') unless(/\S/);
  
  s/\s+//g;
  my $base = $self->base;
  my $more = qr/(?:,(.*))?/;
  my @ranges;
  while(length($_)) {
    my($start, $end, $rest);
    if(/^(\d+)$more$/o) {
      ($start, $end, $rest) = ($1-$base, $1-$base, $2);
    }
    elsif(/^-(\d+)$more$/o) {
      ($start, $end, $rest) = (0, $1-$base, $2);
    }
    elsif(/^(\d+)-(\d+)$more$/o) {
      return $self->alert("Error in column list at: '$1-$2'") if $2 < $1;
      ($start, $end, $rest) = ($1-$base, $2-$base, $3);
    }
    elsif(/^(\d+)-$more$/o) {
      ($start, $end, $rest) = ($1-$base, '*', $2);
    }
    else {
      return $self->alert("Error in column list at: '$_'");
    }
    return $self->alert("Error in column list at: '$_'") if $start < 0;
    push @ranges, [ $start, $end ];
    last unless defined $rest;
    $_ = $rest;
  }
  $self->{_colspec} = \@ranges;
  $self->{_slices} = {};
}


sub row {
  my($self, $r) = @_;

  my $slice = $self->{_slices}->{$#$r} ||= $self->_slice($#$r);
  $self->msg_out(row => [ map { defined($_) ? $_ : '' } @{$r}[@$slice] ]);
}


sub _slice {
  my($self, $last) = @_;

  return [ 
    map {
      $_->[1] eq '*'
      ? ($_->[0]..$last) 
      : ($_->[0]..$_->[1])
    } @{$self->{_colspec}} 
  ];
}


sub dialog_xml {
  return 'file:/home/grant/projects/sf/sprog/glade/select_cols.glade';
  return <<'END_XML';
END_XML
}


1;

__END__


=head1 NAME

Sprog::Gear::SelectColumns - select columns in each row

=head1 DESCRIPTION

Passes only the selected columns between the list input and the list output.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Select Columns

This gear allows you to pass through selected columns from the 'list' input
connector to the 'list' output connector.

You might find this useful for:

=over 4

=item *

re-ordering columns

=item *

discarding columns

=item *

duplicating columns

=back

=head2 Properties

=over 4

=item Columns

Enter the list of columns you want, in the order you want them.  Multiple
columns should be separated with commas and ranges should be specified as
I<n-n>.

=item Base

There are two options for numbering the columns.  If you're not a Perl
programmer, you'll think this is crazy and wonder why anyone would select
anything other than numbering from 1 (the default).  If you I<are> a Perl
programmer, you'll think this is crazy and wonder why anyone would select
anything other than numbering from 0.

=back

=head2 Columns Cookbook

All these examples assume a numbering base of 1.

This will select only the second column:

  2

This will select columns 4, 5 and 6 followed by column 1 (all other columns
will be discarded):

  4-6,1

This will reverse the first two columns, and pass the remaining columns through
untouched:

  2,1,3-

Similarly, this will pass the first three columns through untouched, pass two
copies of the fifth column and discard the rest:

  -3,5,5

=end :sprog-help-text

