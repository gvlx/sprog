package LineGear;

use base qw(
  Sprog::Gear
  Sprog::Gear::InputByLine
);


sub has_input { 1; }

sub new {
  my $class = shift;

  my $self = $class->SUPER::new(@_);
  $self->{lines} = [];

  return $self;
}


sub line {
  my($self, $line) = @_;

  push @{$self->{lines}}, $line;
}


sub lines {
  return @{shift->{lines}};
}


1;

