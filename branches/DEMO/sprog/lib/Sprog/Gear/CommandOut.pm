package Sprog::Gear::CommandOut;

=begin sprog-gear-metadata

  title: Run Command
  type_in: P
  type_out: _

=end sprog-gear-metadata

=cut

use strict;

use base qw(
  Sprog::Gear::OutputToFH
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
    $self->alert('You must enter a command');
    return;
  }

  $self->_run_command($command) or return;

  return $self->SUPER::engage;
}


sub disengage {
  my($self) = @_;

  my($fh);
  $fh = $self->fh_out && close($fh);
  
  $self->SUPER::disengage();
}


sub _run_command {
  my($self, $command) = @_;

  my($fh);
  if(!open $fh, '|-', $command) {
    $self->alert(qq(Can't run "$command"), "$!");
    return;
  }

  $self->fh_out($fh);
}


1;


__END__

=head1 NAME

Sprog::Gear::CommandOut - Run a command and pipe data to it.

=head1 DESCRIPTION

This gear executes the specified command and pipes data into its STDIN.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Run Command Gear

This is an output gear.  It runs a command and passes data from the 'pipe'
input connector to the command's standard input.

=head2 Properties

The Run Command gear has only one property - the command to run.  Type the
command into the text input. 

=end :sprog-help-text

