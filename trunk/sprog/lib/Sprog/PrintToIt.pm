package Sprog::PrintToIt;

sub TIEHANDLE { my $o; return bless \$o, shift; }

sub PRINT {
  shift;
  $_ = join '', @_;
}

1;

=head1 NAME

Sprog::PrintToIt - Capture print calls to $_

=head1 SYNOPSIS

  use Sprog::PrintToIt;

  local(*STDOUT);
  tie(*STDOUT, 'Sprog::PrintToIt');

  print 'This data will end up in $_';

=head1 DESCRIPTION

This module performs one very simple function - it intercepts all attempts to
C<print> to STDOUT and instead stores the arguments to print in the global
variable C<$_> (this variable is sometimes pronounced 'it').  This
functionality is used to allow user code in the C<Sprog::Gear::PerlCode*>
classes to simply call C<print> when generating data for the downstream gear.

=head1 COPYRIGHT 

Copyright 2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut

