package Sprog::Gear::CommandFilter;

=begin sprog-gear-metadata

  title: Run Filter Command
  type_in: P
  type_out: P

=end sprog-gear-metadata

=cut

use strict;

use base qw(
  Sprog::Gear::OutputToFH
  Sprog::Gear::InputFromFH
  Sprog::Gear::CommandDialog
  Sprog::Gear
);

__PACKAGE__->declare_properties(
  command => '',
);

use IPC::Open2;


sub engage {
  my($self) = @_;

  my $command = $self->command;
  if(!defined($command) or $command !~ /\S/) {
    $self->alert('You must enter a filter command');
    return;
  }

  $self->_run_command($command) or return;

  return $self->SUPER::engage;
}


sub disengage {
  my($self) = @_;

  my($fh);
  $fh = $self->fh_out && close($fh);
  $fh = $self->fh_in  && close($fh);
  waitpid($self->{_filter_pid}, 0);
  
  $self->SUPER::disengage();
}


sub file_start {
  my($self, $filename) = @_;

  if(exists($self->{filename})) {
    $self->msg_out(file_end => delete $self->{filename});
  }
  $self->{filename} = $filename;
  $self->msg_out(file_start => $filename);
}


sub file_end {
  my($self, $filename) = @_;
}


sub filename { return shift->{filename}; }


sub _run_command {
  my($self, $command) = @_;

  my $parent = $$;
  my($fh_out, $fh_in);
  $self->{_filter_pid} = eval {
    open2($fh_in, $fh_out, $command) or exit;  # in child only?
  };
  if($@) {
    exit if $parent != $$;  # exec must have failed in child
    $self->alert(qq(Can't run "$command"), "$@");
    return;
  }

  $self->fh_in($fh_in);
  $self->fh_out($fh_out);

  return 1;
}


1;

__END__

=head1 NAME

Sprog::Gear::CommandFilter - Run a command and pipe data through it.

=head1 DESCRIPTION

This gear uses two pipes - one to pass data to the STDIN of an external command
and one to read the STDOUT from that command.  Both input and output connectors
are 'pipe' connectors.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Run Filter Command Gear

The 'Run Filter Command' gear allows you to run a command, and pass data
through it.  Data received through the 'pipe' connector from the upstream gear
is pass into the command.  Output from the command is captured and passed out
the pipe connector to the downstream gear.

You would usually use this gear to capture plain text written to STDOUT by a
command, but it can also be used for 'binary' data such as images.

=head2 Properties

The Run Filter Command gear has only one property - the command to run.  Type
the command into the text input. 

=end :sprog-help-text

