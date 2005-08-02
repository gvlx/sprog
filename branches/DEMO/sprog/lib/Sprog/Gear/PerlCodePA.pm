package Sprog::Gear::PerlCodePA;

=begin sprog-gear-metadata

  title: Perl Code
  type_in: P
  type_out: A

=end sprog-gear-metadata

=cut

use strict;
use warnings;

use base qw(
  Sprog::Mixin::InputByLine
  Sprog::Gear::PerlBase
);


sub _sub_preamble {
  return <<'END_PERL';
      my($self) = @_;

      my @row;
      my $r = \@row;

      LINE: {
# line 1 "your code"
END_PERL
}


sub _sub_postamble {
  return <<'END_PERL';
        $self->msg_out(row => $r) if @$r;
      }
END_PERL
}


sub line {
  my $self  = shift;

  if(ref $self->{perl_sub}) {
    local($_) = shift;
    $self->{perl_sub}->($self);
  }
}


1;

__END__


=head1 NAME

Sprog::Gear::PerlCodePA - convert 'pipe' data to 'list' data via Perl code

=head1 DESCRIPTION

This gear is for converting line-by-line input to rows of field values.  It
allows the user to define a snippet of Perl code that will implement the
conversion for each line of input.  The code snippet is wrapped with a small
amount of boilerplate code similar to the following:

  $_ = $input_line;
  @row = ();
  LINE: {
    # Perl snippet inserted here
    $self->msg_out(row => \@row) if @row;
  }

There is no default conversion, so if the code snippet does not assign to 
C<@row> then no output message will be generated.

For consistency with other PerlCode gears, the scalar C<$r> contains a
reference to the @row.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 



=begin :sprog-help-text

=head1 Perl Code Gear (Pipe to List)

This 'Perl Code' gear is used to transform lines of data from the 'pipe' input
connector into a form suitable for the 'list' output connector.  There is no
default conversion - if you don't add some code you'll get no output.

This gear is commonly used for parsing lines from text files (such as logs)
into separate fields.

=head2 Properties

This Perl Code gear has only one property - the Perl code to be run.  Type it
in or paste it from the clipboard.

=head2 Perl Wrapper

Your Perl code will be wrapped in something like this:

  $_ = $input_line;
  @row = ();
  LINE: {
    # Perl snippet inserted here
    $self->msg_out(row => \@row) if @row;
  }

When your code snippet executes, the line of input data will be in C<$_>.  You
can use

  next LINE;

to skip to the next line without passing the current line down to the next
gear.

Or you can assign some values to C<@row> to generate an output C<row> event.

=head2 Perl Code Cookbook

Obviously, if you don't know any Perl, this gear is going to be of limited use
to you, but here are a few snippets that might give you an idea of the
possibilities.

A naive CSV parser (doesn't handle quoting, escaping or embedded newlines):

  chomp;                   # Remove the trailing newline
  @row = split /,/;

For a more complex example, let's imagine your building security system logs
which card numbers were used to enter and exit each door:

  2005-05-15@06:13 3/12 8235717 entry
  2005-05-15@06:15 3/12 8235717 exit
  2005-05-15@07:59 1/6 8153901 entry

You might decide to split out the date, time, floor, door, card and event-type
into separate fields using a regular expression, and then focus on events that
occurred after 9:30pm

  @row = /^(\d\d\d\d-\d\d-\d\d)@(\d\d:\d\d) (\d+)/(\d+) (\d+) (\w+)/;
  next LINE if $row[1] lt '21:30';

=head2 Further Reading

The L<introduction to regular expressions|Sprog::help::regex_intro> is a good 
place to start learning about pattern matching in Perl.

If you're new to Perl, the L<perlintro> manual page might be helpful.  Also the
list of L<built-in functions|perlfunc> will give you some ideas.

Both of the documents are likely to be a bit intimidating for non-programmers,
however there are many good introductory books available.

=end :sprog-help-text

