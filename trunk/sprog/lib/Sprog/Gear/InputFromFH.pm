package Sprog::Gear::InputFromFH;


use constant BUF_SIZE => 65536;


sub fh_in { $_[0]->{fh_in} = $_[1] if(@_ > 1); return $_[0]->{fh_in}; }

sub register   { $_[0]->machine->register_data_provider($_[0]); }
sub unregister { $_[0]->machine->unregister_data_provider($_[0]); }


sub send_data {
  my($self) = @_;

  return if $self->{in_tag};  # We're already waiting
  my $fh = $self->fh_in or return;
  $self->{in_tag} = $self->app->add_io_reader($fh, sub { $self->_data_ready });
}


sub _data_ready {
  my($self) = @_;

  delete $self->{in_tag};
  my $buf;
  if(sysread($self->fh_in, $buf, BUF_SIZE)) {
    $self->msg_out(data => $buf);
  }
  else {
    my $filename = undef;
    $filename = $self->filename if($self->can('filename'));
    $self->msg_out(file_end => $filename);
    $self->unregister();
    $self->fh_in(undef);
  }
  
  $self->work_done(1);
  
  return 0;               # don't immediately re-queue the file event
}


1;

=head1 NAME

Sprog::Gear::InputFromFH - a 'mixin' class for gears reading input from a file handle

=head1 SYNOPSIS

  use base qw(
    Sprog::Gear
    Sprog::Gear::InputFromFH
  );

  sub prime {
    my($self) = @_;

    my $fh = $self->_open_file or return;
    $self->fh_in($fh);
    $self->register();

    return $self->SUPER::prime;
  }


=head1 DESCRIPTION

This mixin is for use by gears which need to read from a file handle (ie:
files, pipes, sockets ...).  It provides the appropriate links into the
event loop to read using non-blocking IO and to pass the data read from the file
handle to the next gear as a C<data> message.


=head1 METHODS

=head2 fh_in ( filehandle )

The gear class is responsible for opening the file handle and then passing it
to this method to make it available to the other methods in this class.

=head2 register ( )

Call this method to have the class register itself with the machine, as a data
provider.

=head2 unregister ( )

This method will be called automatically when the end of file is reached.  It
tells the machine that this gear has no more data to provide.

=head2 send_data ( )

The machine will call this method when it needs more data.  When the EOF is
reached, this method will arrange for the gear to unregister itself as a
data provider.

=head1 COPYRIGHT 

Copyright 2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut


