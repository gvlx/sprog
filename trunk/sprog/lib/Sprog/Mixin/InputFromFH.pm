package Sprog::Mixin::InputFromFH;

use Sprog::Debug qw($DBG);

use constant BUF_SIZE => 65536;


sub fh_in { $_[0]->{fh_in} = $_[1] if(@_ > 1); return $_[0]->{fh_in}; }


sub send_data {
  my($self) = @_;

  $DBG && $DBG->(ref($self) . ' ' . ($self->{in_tag} ? 'already waiting' : 'adding IO reader'));
  return if $self->{in_tag};  # We're already waiting
  my $fh = $self->fh_in or return;
  $self->{in_tag} = $self->app->add_io_reader($fh, sub { $self->_can_read });
}


sub _can_read {
  my($self) = @_;

  $DBG && $DBG->(ref($self) . ' _can_read');
  delete $self->{in_tag};
  my $buf;
  my $fh = $self->fh_in;
  if(sysread($fh, $buf, BUF_SIZE)) {
    $DBG && $DBG->(ref($self) . ' read ' . length($buf) . ' bytes');
    $self->msg_out(data => $buf);
  }
  else {
    $DBG && $DBG->(ref($self) . ' EOF');
    close($fh) if $fh;
    $self->fh_in(undef);
    my $filename = undef;
    $filename = $self->filename if($self->can('filename'));
    $self->msg_out(file_end => $filename);
    $self->disengage();
  }
  
  $self->work_done(1);
  
  return 0;               # don't immediately re-queue the file event
}


sub stop {
  my $self = shift;

  if(my $tag = delete $self->{in_tag}) {
    $self->app->cancel_event($tag);
  }
}


1;

=head1 NAME

Sprog::Mixin::InputFromFH - a 'mixin' class for gears reading input from a file handle

=head1 SYNOPSIS

  use base qw(
    Sprog::Mixin::InputFromFH
    Sprog::Gear
  );

  sub engage {
    my($self) = @_;

    my $fh = $self->_open_file or return;
    $self->fh_in($fh);

    return $self->SUPER::engage;
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

=head2 send_data ( )

The machine will call this method when it needs more data.  The default 
implementation will set up an IO watch event waiting for data to arrive on
the filehandle in C<fh_in>.  When the data arrives, it will be sent as a
C<data> message using the gear's C<msg_out> method - which you can override
if you need to mess with the data.

When the EOF is reached, the IO watch event handler will call the gear's
C<disengage> method to remove it from the geartrain.

=head1 COPYRIGHT 

Copyright 2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut


