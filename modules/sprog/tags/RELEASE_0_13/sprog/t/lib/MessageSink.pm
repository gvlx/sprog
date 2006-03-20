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


sub new {
  my $class = shift;

  my $self = $class->SUPER::new(@_);
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
sub data       { push @{shift->{messages}}, [ data       => shift ] }
sub file_end   { push @{shift->{messages}}, [ file_end   => shift ] }


sub messages {
  return @{shift->{messages}};
}


1;

