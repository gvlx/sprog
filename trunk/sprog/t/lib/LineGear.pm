package LineGear;

=begin sprog-gear-metadata

  title: Line Gear
  type_in: P
  type_out: _

=end sprog-gear-metadata

=cut

use base qw(
  Sprog::Gear
  Sprog::Gear::InputByLine
);


sub has_input { 1; }

sub new {
  my $class = shift;

  my $self = $class->SUPER::new(@_);
  $self->reset;

  return $self;
}


sub prime {
  my $self = shift;

  $self->reset;
  $self->SUPER::prime;
}


sub reset { shift->{lines} = [] };


sub line {
  my($self, $line) = @_;

  push @{$self->{lines}}, $line;
}


sub lines {
  return @{shift->{lines}};
}


1;

