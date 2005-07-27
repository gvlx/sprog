package AccTest;

use base qw(Sprog::Accessor);

__PACKAGE__->mk_accessors(qw(
  prop1
  prop2
  -prop3
));


package AccTest2;

use base qw(Sprog::Accessor);

__PACKAGE__->mk_accessors(qw(
  propA
  propB
  -propC
));


sub new {
  my $class = shift;

  my $self = $class->SUPER::new(@_);

  $self->propA(uc($self->propA));

  return $self;
}

1;
