package LineGear;

use base qw(
  Sprog::Gear::Bottom
  Sprog::Gear::InputByLine
);


sub has_input { 1; }

sub new {
  my $class = shift;

  my $self = $class->SUPER::new(@_);
  $self->reset;

  return $self;
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

