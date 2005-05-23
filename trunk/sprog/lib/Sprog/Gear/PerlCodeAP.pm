package Sprog::Gear::PerlCodeAP;

=begin sprog-gear-metadata

  title: Perl Code
  type_in: A
  type_out: P

=end sprog-gear-metadata

=cut

use strict;
use warnings;

use base qw(Sprog::Gear::PerlBase);

use Sprog::PrintProxy;


sub engage {
  my $self = shift;

  $self->{proxy} ||= Sprog::PrintProxy->new($self);

  return $self->SUPER::engage;
}


sub _sub_preamble {
  return <<'END_PERL';
      my($self, $r) = @_;

      our @row;
      *row = $r;

      ROW: {
# line 1 "your code"
END_PERL
}


sub _sub_postamble {
  return <<'END_PERL';
      }
END_PERL
}


sub row {
  my($self, $r) = @_;

  return unless ref $self->{perl_sub};

  my $stdout = select $self->{proxy};
  $self->{perl_sub}->($self, $r);
  select $stdout;
}


sub print {
  my $self = shift;

  $self->msg_out(data => join('', @_));
}

1;

__END__


=head1 NAME

Sprog::Gear::PerlCodeAP - convert 'list' data to 'pipe' data via Perl code

=head1 DESCRIPTION

This gear allows the user to define a snippet of Perl code that will examine
the input rows and produce a 'pipe' output stream.

The user-supplied code snippet is wrapped with a small amount of boilerplate
code:

  $r = \@row;

  RECORD: {
    # Perl snippet here
  }

The default behaviour is to produce no output at all.

The input record is available in both the array C<@row> and the arrayref C<$r>
(one is an alias for the other).  The user-supplied code should use C<print> to
send data to the next downstream gear.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Perl Code Gear (List to Pipe)

This 'Perl Code' gear is used to transform data from the 'list' input
connector into a form suitable for the 'pipe' output connector.

The default behaviour is to produce no output at all.

=head2 Properties

The Perl Code gear has only one property - the Perl code to be run.  Type it
in or paste it from the clipboard.

=head2 Perl Wrapper

Your Perl code will be wrapped in something like this:

  ROW: {
    # Your Perl snippet here
  }

The record will be available in an array called C<@row> (and also via an
arrayref alias C<$r>).

Perl's built-in C<print> function is overridden in this context to pass the
data down to the next gear.

You can use

  next ROW;

to skip to the next record.

=head2 Perl Code Cookbook

This one-liner takes a row of three fields (surname, first name and age), swaps
the field order around and outputs a one-line sentence:

  print "$row[1] $row[0] is $row[2] years old\n";

so this input:

  'Smith', 'John', '25'

is translated to this output:

  John Smith is 25 years old

I<Note: the elements in a Perl array are numbered from zero, so in the above
example, the three fields are numbered 0, 1 and 2 respectively).

=end :sprog-help-text

