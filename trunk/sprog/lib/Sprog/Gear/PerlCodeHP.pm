package Sprog::Gear::PerlCodeHP;

use strict;

use Sprog::PrintProxy;

use base qw(Sprog::Gear::PerlBase);

sub input_type   { 'H'; }


sub prime {
  my $self = shift;

  $self->{proxy} ||= Sprog::PrintProxy->new($self);

  return $self->SUPER::prime;
}


sub _sub_preamble {
  return <<'END_PERL';
      my($self, $r) = @_;

      our %rec;
      *rec = $r;

      RECORD: {
# line 1 "your code"
END_PERL
}


sub _sub_postamble {
  return <<'END_PERL';
      }
END_PERL
}


sub record {
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

Sprog::Gear::PerlCode - convert 'record' data to 'pipe' data via Perl code

=head1 DESCRIPTION

This gear allows the user to define a snippet of Perl code that will examine
the input records and produce a 'pipe' output stream.

The user-supplied code snippet is wrapped with a small amount of boilerplate
code:

  $r = \%rec;

  RECORD: {
    # Perl snippet here
  }

The default behaviour is to produce no output at all.

The input record is available in the both hash C<%rec> and the hashref C<$r>
(one is an alias for the other).  The user-supplied code should use C<print> to
send data to the next downstream gear.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=head1 HELP VIEWER TEXT

=for sprog-help-text

=head1 Perl Code Gear (Record to Pipe)

This 'Perl Code' gear is used to transform data from the 'record' input
connector to produce data for the 'pipe' output connector.

The default behaviour is to produce no output at all.

=head2 Properties

The Read File gear has only one property - the Perl code to be run.  Type it
in or paste it from the clipboard.

=head2 Perl Wrapper

Your Perl code will be wrapped in something like this:

  RECORD: {
    # Your Perl snippet here
  }

The record will be available in a hash called C<%rec> (and also via a hashref
alias C<$r>).

Perl's built-in C<print> function is overridden in this context to pass the
data down to the next gear.

You can use

  next RECORD;

to skip to the next record.

=head2 Perl Code Cookbook

To print each key and value with a blank line between records:

  while(my($key, $value) = each %rec) {
    print "$key: $value\n";
  }
  print "\n";

This snippet processes the output from the
L<Parse Apache Log|Sprog::Gear::ApacheLogParse> gear, identifies all 404
errors and prints out the original request and the referring URL:

  next RECORD unless ($rec{status} == 404);
  print "$rec{request}\n";
  print "$rec{Referer}\n";

I<Remember, both Perl language keywords and Perl hash keys are case sensitive.
And yes, the word referrer is misspelled in the HTTP spec>.

