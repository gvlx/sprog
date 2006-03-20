package Sprog::Debug;


our $DBG = undef;

use base qw(Exporter);

our @EXPORT_OK = qw($DBG);

sub _init {
  my $opt = shift;

  return unless $opt->{debug};

  require "IO/Handle.pm";
  require "POSIX.pm";

  open my $dbg, '>', 'sprog.dbg' or die "open(sprog.dbg): $!";
  $dbg->autoflush(1);

  $DBG = sub {
    my $time = POSIX::strftime('%T', localtime);
    foreach (@_) {
      my $msg = $_;
      if(ref($msg)) {
        local($YAML::UseHeader) = 0;
        local($YAML::SortKeys)  = 1;
        $msg = YAML::Dump([$msg]) . "\n";
      }
      $msg = "$msg\n" unless $msg =~ /\n\Z/s;
      $msg =~ s{^}{$time  }mg;
      print $dbg $msg;
    }
  };
}

1;


__END__


=head1 NAME

Sprog::Debug - routine for logging debug messages.

=head1 SYNOPSIS

  use Sprog::Debug qw($DBG);

  ...

  $DBG && $DBG->("Some debugging message", $data_ref);

=head1 DESCRIPTION

If Sprog is started with the C<--debug> (or C<-d>) switch, then debugging
messages will be logged to F<sprog.dbg> in the current directory.

A module that wants to log debug messages should import the C<$DBG> variable.
This scalar will either be undefined (the default) or if debugging was enabled,
it will contain a reference to a subroutine.

To log a message, a module should first check that $DBG is defined and if it
is should call it, passing a list of messages and/or data references.

Each argument passed to the debug logger will be handled as follows:

=over 4

=item *

If the item is a reference rather than a plain scalar will be dumped using
L<YAML>.

=item *

Non-references will simply be written to the log, with a newline appended if
the string did not end in one.

=back

The debug logger routine will prepend a timestamp to each line logged.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut


