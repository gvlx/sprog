package Pstax::Gear::PerlCodeHP;

use strict;

use base qw(Pstax::Gear::PerlCode);

sub input_type   { 'H'; }

sub sub_preamble {
  return <<END_PERL;
    sub { 
      my \$self = shift;
      my %r = %\$_;

      LINE: {
#line 0
END_PERL
}


sub sub_postamble {
  return <<END_PERL;
        \$self->msg_out(line => \$_);
      }
    }
END_PERL
}


sub data {
  my $self  = shift;
  local($_) = shift;

  $self->{perl_sub}->($self) if(ref $self->{perl_sub});
}


sub line {                     # this should never happen :-)
  my($self, $line) = @_;

  $self->msg_out(line  => $line);
}


1;
