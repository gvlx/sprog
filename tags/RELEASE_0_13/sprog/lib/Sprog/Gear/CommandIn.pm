package Sprog::Gear::CommandIn;

=begin sprog-gear-metadata

  title: Run Command
  type_in: _
  type_out: P

=end sprog-gear-metadata

=cut

use strict;

use base qw(
  Sprog::Gear::InputFromFH
  Sprog::Gear::CommandDialog
  Sprog::Gear
);

__PACKAGE__->declare_properties(
  command => '',
);

sub engage {
  my($self) = @_;

  my $command = $self->command;
  if(!defined($command) or $command !~ /\S/) {
    $self->alert('You must enter an input command');
    return;
  }

  my $fh = $self->_run_command($command) or return;
  $self->fh_in($fh);

  return $self->SUPER::engage;
}


sub _run_command {
  my($self, $command) = @_;

  my($fh);
  if(!open $fh, '-|', $command) {
    $self->alert(qq(Can't run "$command"), "$!");
    return;
  }
  $self->msg_out(file_start => undef);

  return $fh;
}


1;

__END__

=head1 NAME

Sprog::Gear::CommandIn - Run a command and read its output

=head1 DESCRIPTION

This is a data input gear.  It runs a command, captures the STDOUT from the
command and passes it downstream using a 'pipe' connector.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Run Command Gear

The 'Run Command' gear allows you to run a command, capture its output and pass
the data out through a 'pipe' connector.

You would usually use this gear to capture plain text written to STDOUT by a
command, but it can also be used for 'binary' data such as images.

=head2 Properties

The Run Command gear has only one property - the command to run.  Type the
command into the text input. 

For example this command would retrieve the weather forecast for New Zealand's
capital city:

  wget -q -O - http://weather.yahoo.com/forecast/NZXX0049_c.html

=end :sprog-help-text

