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

