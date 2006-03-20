package TextGear;

use base qw(
  Sprog::Gear::Bottom
);

__PACKAGE__->mk_accessors(qw(
  text
));


sub prime {
  my $self = shift;

  $self->text('');
  $self->SUPER::prime();
}


sub has_input { 1; }


sub data {
  my($self, $data) = @_;

  $self->{text} .= $data;
}


1;

