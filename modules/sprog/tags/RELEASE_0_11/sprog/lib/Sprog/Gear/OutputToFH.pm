package Sprog::Gear::OutputToFH;

use Sprog::Debug qw($DBG);

use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);



sub fh_out {
  my $self = shift;

  if(@_) {
    my $fh = $self->{fh_out} = shift;

    if($fh) {
      my $flags = fcntl($fh, F_GETFL, 0)
                  or die "Can't get flags for output fh: $!\n";

      $flags = fcntl($fh, F_SETFL, $flags | O_NONBLOCK)
                  or die "Can't set flags for output fh: $!\n";
    }

    $self->{buffer} = '';
    $self->{close_on_flush} = 0;
  }
  return $self->{fh_out}; 
}


sub data {
  my($self, $data) = @_;

  $self->{buffer} .= $data;

  return unless length $self->{buffer};
  return if $self->{out_tag};  # We're already waiting
  my $fh = $self->fh_out or return;
  $self->sleeping(1);
  $self->{out_tag} = $self->app->add_io_writer($fh, sub { $self->_can_write });
}


sub no_more_data {
  my $self = shift;

  if(length $self->{buffer}) {                # data left to send
    $self->{close_on_flush} = 1;
  }
  else {
    $self->_close_output_fh;
  }
}


sub _can_write {
  my $self = shift;

  $DBG && $DBG->(ref($self) . ' _can_write');

  my $fh = $self->fh_out;
  my $i  = syswrite $fh, $self->{buffer};

  if(!defined $i) {
    warn "Error while writing: $!\n";
    $self->_close_output_fh;
  }
  else {
    substr $self->{buffer}, 0, $i, '';
    $DBG && $DBG->(
      ref($self) . " wrote $i bytes " . length($self->{buffer}) . " to go"
    );
  }

  return 1 if(length $self->{buffer});

  # No more data left to send

  if($self->{close_on_flush}) {
    $self->_close_output_fh;
  }

  $self->sleeping(0);          # will wake scheduler if necessary
  delete $self->{out_tag};
  return 0;
}


sub _close_output_fh {
  my $self = shift;

  my $fh = delete $self->{fh_out};
  close $fh if $fh;
}


1;


=head1 NAME

Sprog::Gear::OutputToFH - a 'mixin' class for gears writing output to a file handle

=head1 SYNOPSIS

  use base qw(
    Sprog::Gear
    Sprog::Gear::OutputToFH
  );

  sub engage {
    my($self) = @_;

    my $fh = $self->_open_output_file or return;
    $self->fh_out($fh);

    return $self->SUPER::engage;
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


