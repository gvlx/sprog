package RecordSink;

=begin sprog-gear-metadata

  title: Record Sink
  type_in: H
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


sub reset { shift->{records} = [] };


sub record {
  my($self, $rec) = @_;

  push @{$self->{records}}, $rec;
}


sub records {
  return @{shift->{records}};
}


1;

