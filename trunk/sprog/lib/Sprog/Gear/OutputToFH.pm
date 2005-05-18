package Sprog::Gear::OutputToFH;

sub fh_out {
  my $self = shift;

  if(@_) {
    $self->{fh_out} = shift;
    $self->{buffer} = '';
  }
  return $self->{fh_out}; 
}


sub data {
  my($self, $data) = @_;

  $self->{buffer} .= $data;

  return 1 if $self->{out_tag};  # We're already waiting
  my $fh = $self->fh_out or return;
  $self->sleeping(1);
  $self->{out_tag} = $self->app->add_io_writer($fh, sub { $self->_can_write });
  return 1;
}


sub _can_write {
  my $self = shift;

  my $fh = $self->fh_out;
  my $i  = syswrite $fh, $self->{buffer};
  
  substr $self->{buffer}, 0, $i, '';

  if(length $self->{buffer}) {                # data left to send
    return 1;
  }

  $self->sleeping(0);
  $self->machine->enable_idle_handler;
  delete $self->{out_tag};
  return 0;
}


1;


=head1 NAME

Sprog::Gear::OutputToFH - a 'mixin' class for gears writing output to a file handle

=head1 SYNOPSIS

  use base qw(
    Sprog::Gear
    Sprog::Gear::OutputToFH
  );

  sub prime {
    my($self) = @_;

    my $fh = $self->_open_output_file or return;
    $self->fh_out($fh);

    return $self->SUPER::prime;
  }


=head1 DESCRIPTION

This mixin is for use by gears which need to write to a file handle (ie: files,
pipes, sockets ...).  It provides the appropriate links into the event loop to
write using non-blocking IO.


=head1 METHODS

=head2 fh_out ( filehandle )

The gear class is responsible for opening the file handle and then passing it
to this method to make it available to the other methods in this class.

=head2 data ( data )

When the gear receives a C<data> message, this method will be invoked and the
data will be queued to be written to the filehandle.

=head1 COPYRIGHT 

Copyright 2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut


