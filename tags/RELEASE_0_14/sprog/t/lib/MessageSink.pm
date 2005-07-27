package MessageSink;

=begin sprog-gear-metadata

  title: Message Sink
  type_in: P
  type_out: _
  no_properties: 1

=end sprog-gear-metadata

=cut

use base qw(
  Sprog::Gear
);

__PACKAGE__->mk_accessors(qw(
  concatenate_data
));


sub new {
  my $class = shift;

  my $self = $class->SUPER::new(concatenate_data => 0, @_);
  $self->reset;

  return $self;
}


sub engage {
  my $self = shift;

  $self->reset;
  $self->SUPER::engage;
}


sub reset { shift->{messages} = [] };


sub file_start { push @{shift->{messages}}, [ file_start => shift ] }
sub file_end   { push @{shift->{messages}}, [ file_end   => shift ] }

sub data { 
  my $self = shift;

  if($self->concatenate_data) {
    if(@{$self->{messages}} and $self->{messages}->[-1]->[0] eq 'data') {
      $self->{messages}->[-1]->[1] .= shift;
      return;
    }
  }
  push @{$self->{messages}}, [ data => shift ];
}


sub messages {
  return @{shift->{messages}};
}


1;

