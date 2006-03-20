package MessageSource;

=begin sprog-gear-metadata

  title: Message Source Gear
  type_in: _
  type_out: P

=end sprog-gear-metadata

=cut

use base qw(
  Sprog::Gear
);


sub messages {
  my $self = shift;

  $self->{messages} = [ @_ ];
}


sub send_data {
  my $self = shift;

  while(@{$self->{messages}}) {
    my $msg = shift @{$self->{messages}};
    $self->msg_out(@$msg);
  }
  $self->disengage;
}

1;

