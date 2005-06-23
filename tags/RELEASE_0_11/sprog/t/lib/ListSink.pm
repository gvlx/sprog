package ListSink;

=begin sprog-gear-metadata

  title: List Sink
  type_in: A
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


sub reset { shift->{rows} = [] };


sub row {
  my($self, $row) = @_;

  push @{$self->{rows}}, $row;
}


sub rows {
  return @{shift->{rows}};
}


1;

