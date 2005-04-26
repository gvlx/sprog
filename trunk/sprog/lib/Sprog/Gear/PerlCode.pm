package Sprog::Gear::PerlCode;

use strict;

use Sprog::PrintToIt;

use base qw(
  Sprog::Gear::PerlBase
  Sprog::Gear::InputByLine
);


sub _sub_preamble {
  return <<END_PERL;
      my \$self = shift;

      local(*STDOUT);
      tie(*STDOUT, 'Sprog::PrintToIt');

      LINE: {
# line 1 "your code"
END_PERL
}


sub _sub_postamble {
  return <<END_PERL;
        \$self->msg_out(data => \$_);
      }
END_PERL
}

sub line {
  my $self  = shift;

  if(ref $self->{perl_sub}) {
    local($_) = shift;
    $self->{perl_sub}->($self) 
  }
  else {
    $self->msg_out(data => @_);
  }
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
    # Perl snippet here
    $self->msg_out(data => $_);
  }

Thus, the default behaviour is to take the line of input in C<$_> and pass
it directly to the next downstream gear.  The code snippet can alter the
contents of C<$_> and can use C<next> to prevent the line being passed to
the next gear.

Note, the builtin C<print> function is overridden to assign its arguments to
C<$_>.  So these two lines are equivalent:

  print uc($_);
  $_  = uc($_);


=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut


