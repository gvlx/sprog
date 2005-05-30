package Sprog::Gear::PerlCode;

=begin sprog-gear-metadata

  title: Perl Code
  type_in: P
  type_out: P

=end sprog-gear-metadata

=cut

use strict;

use Sprog::PrintProxy;

use base qw(
  Sprog::Gear::InputByLine
  Sprog::Gear::PerlBase
);


sub engage {
  my $self = shift;

  $self->{proxy} ||= Sprog::PrintProxy->new($self);

  return $self->SUPER::engage;
}


sub _sub_preamble {
  return <<'END_PERL';
      my $self = shift;

      LINE: {
# line 1 "your code"
END_PERL
}


sub _sub_postamble {
  return <<'END_PERL';
        print $_;
      }
END_PERL
}


sub line {
  my $self  = shift;

  if(ref $self->{perl_sub}) {
    local($_) = shift;
    my $stdout = select $self->{proxy};
    $self->{perl_sub}->($self);
    select $stdout;
  }
  else {
    $self->msg_out(data => @_);
  }
}


sub print {
  my $self = shift;
  $self->msg_out(data => join('', @_));
}

1;

__END__


=head1 NAME

Sprog::Gear::PerlCode - execute your own Perl code for each line of input

=head1 DESCRIPTION

This gear allows the user to define a snippet of Perl code that will be
executed for each line of input.  The code snippet is wrapped with a small
amount of boilerplate code (similar in purpose to Perl's C<-p> option):

  $_ = $input_line;
  LINE: {
    # Perl snippet inserted here
    print $_;
  }

The built-in C<print> function is also overridden to pass its arguments to the
next downstream gear as a C<data> message.

Thus, the default behaviour is to take the line of input in C<$_> and pass
it directly to the next downstream gear.  The code snippet can alter the
contents of C<$_>.  It can also call C<print> as many times as it wants to generate
additional lines of output.

I<Note: unlike Perl's -p option, the C<print> is not in a C<continue> block
so if you call next, the print will be skipped>.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 



=begin :sprog-help-text

=head1 Perl Code Gear

The 'Perl Code' gear allows you to set up a small chunk of Perl code that will 
get run for each line of input.

The default behaviour (if you don't add any code) is to pass each line
unaltered out through the pipe connector to the next downstream gear.

If you do add some Perl code, that code can alter the data, print extra lines
of data or skip the line to prevent it being passed on.

=head2 Properties

The Read File gear has only one property - the Perl code to be run.  Type it
in or paste it from the clipboard.

=head2 Perl Wrapper

Your Perl code will be wrapped in something like this:

  $_ = $input line;
  LINE: {
    # Your Perl snippet here
    print $_;
  }

Perl's built-in C<print> function is overridden in this context to pass the
data down to the next gear.

When your code snippet executes, the line of input data will be in C<$_>.  You
can use

  next LINE;

to skip to the next line without passing the current line down to the next
gear.

=head2 Perl Code Cookbook

Obviously, if you don't know any Perl, this gear is going to be of limited use
to you, but here are a few snippets that might give you an idea of the
possibilities.

Put the current date and time onto the start of each line:

  print localtime() . ': ';

Skip lines that don't start with 'From: ' and only pass the remainder of the
line for those that do:

  next LINE unless /^From: (.*)$/;
  $_ = "$1\n";

=head2 Further Reading

If you're new to Perl, the L<perlintro> manual page might be helpful.  Also the
list of L<built-in functions|perlfunc> will give you some ideas.

Both of the documents are likely to be a bit intimidating for non-programmers,
however there are many good introductory books available.

=end :sprog-help-text

