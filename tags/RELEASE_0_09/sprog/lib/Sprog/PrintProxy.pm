package Sprog::PrintProxy;

use Symbol ();

sub new {
  my($class, $target) = @_;

  my $fh = Symbol::gensym;

  tie(*$fh, 'Sprog::PrintProxyTie', $target);

  return $fh;
}


package Sprog::PrintProxyTie;

sub TIEHANDLE {
  my($class, $target) = @_; 
  return bless \$target, $class;
}

sub PRINT {
  my $target = shift;
  $$target->print(@_);
}

1;

=head1 NAME

Sprog::PrintProxy - filehandle-like object which proxies prints to another object

=head1 SYNOPSIS

  use Sprog::PrintProxy;

  my $fh = Sprog::PrintProxy->new($gear);

  my $stdout = select $fh;      # remember where STDOUT used to go

  print "Test Message\n";       # translated to $gear->print("Test Message\n");

  select $stdout;a              # reconnect old STDOUT

  print "Test Message\n";       # normal print to STDOUT


=head1 DESCRIPTION

This object intercepts all prints to STDOUT and turns them into C<<
$object->print >> where C<$object> is the argument passed to the constructor.

The point of all this silliness is to allow a Perl code snippet executing in
a C<Sprog::Gear::PerlCode*> gear to call C<print> and have the arguments passed
to the next downstream gear.

=head1 COPYRIGHT 

Copyright 2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut

