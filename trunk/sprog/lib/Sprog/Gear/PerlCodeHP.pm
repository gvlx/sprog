package Sprog::Gear::PerlCodeHP;

use strict;

use Sprog::PrintToIt;

use base qw(Sprog::Gear::PerlBase);

sub input_type   { 'H'; }

sub _sub_preamble {
  return <<'END_PERL';
      my($self, $r) = @_;

      our %rec;
      *rec = $r;

      local(*STDOUT);
      tie(*STDOUT, 'Sprog::PrintToIt');

      RECORD: {
# line 1 "your code"
END_PERL
}


sub _sub_postamble {
  return <<'END_PERL';
        $self->msg_out(data => $_) if length;
      }
END_PERL
}


sub record {
  my($self, $r) = @_;
  local($_) = '';

  $self->{perl_sub}->($self, $r) if(ref $self->{perl_sub});
}


1;

__END__



=head1 NAME

Sprog::Gear::PerlCode - execute your own Perl code for each input record

=head1 DESCRIPTION

WARNING: This gear is alpha code - the API may change.

This gear allows the user to define a snippet of Perl code that will be
executed for each input record.  The code snippet is wrapped with a small
amount of boilerplate code:

  $r = \%rec;
  $_ = '';

  RECORD: {
    # Perl snippet here
    $self->msg_out(data => $_) if length;
  }

Thus, the default behaviour is to make the input record available in the hash
C<%rec> and the hashref C<$r> and to copy the resulting contents of $_ to the
next downstream gear.  If nothing is assigned to C<$_> then no data will be
passed to the next gear.  The code snippet can alter the contents of C<$_> and
can use C<next> to short-circuit the output message.

Note, the builtin C<print> function is overridden to assign its arguments to
C<$_>.  So these two lines are equivalent:

  print "$rec{host}\n";
  $_  = "$rec{host}\n";

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut


