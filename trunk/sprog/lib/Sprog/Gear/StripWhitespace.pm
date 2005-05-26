package Sprog::Gear::StripWhitespace;

=begin sprog-gear-metadata

  title: Strip Whitespace
  type_in: A
  type_out: A

=end sprog-gear-metadata

=cut

use strict;
use warnings;

use base qw(Sprog::Gear);

__PACKAGE__->declare_properties(
  strip_leading   => 1,
  strip_trailing  => 1,
  collapse_spaces => 0,
  collapse_lines  => 0,
  strip_all       => 0,
);


sub row {
  my($self, $r) = @_;

  my @f = @$r; # make a copy
  foreach (@f) {
    s/[\r\n]+/ /g   if $self->{collapse_lines};
    if($self->{strip_all}) {
      s/[ \t]+//g;
    }
    else {
      s/\t+/ /g       if $self->{collapse_spaces};
      s/[ \t]{2,}/ /g if $self->{collapse_spaces};
      s/\A[ \t]+//    if $self->{strip_leading};
      s/[ \t]+\Z//    if $self->{strip_trailing};
    }
  }

  $self->msg_out(row => \@f);
}


sub dialog_xml {
#  return 'file:/home/grant/projects/sf/sprog/glade/select_cols.glade';
  return <<'END_XML';
END_XML
}


1;

__END__


=head1 NAME

Sprog::Gear::StripWhitespace - Remove selected whitespace from fields in each row

=head1 DESCRIPTION

Passes all fields from list input to list output but removes selected
whitespace enroute.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Strip Whitespace Gear

This gear allows you to remove some or all whitespace characters from each
field of each row received from the 'list' input connector.  All fields
are passed out the 'list' output connector.

=head2 Properties

You can choose any combination of the following on/off properties:

=over 4

=item Strip Leading Whitespace

Removes all space or tab characters at the start of each field.

=item Strip Trailing Whitespace

Removes all space or tab characters at the end of each field.

=item Collapse Multiple Spaces

Within a field (ie: not just at the beginning or end), replace any tab or any
sequence of two or more consecutive space or tab characters with a single space

=item Collapse Newlines

When this option is turned on, each newline character will be changed to a
single space.

=item Strip All Whitespace

If this option is turned on, all spaces, tabs and optionally newlines will be
removed, regardless of whether they are at the start, end or middle of a field.

=back

=end :sprog-help-text

