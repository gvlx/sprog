package TextGear;

=begin sprog-gear-metadata

  title: Text Gear
  type_in: P
  type_out: _

=end sprog-gear-metadata

=cut

use base qw(
  Sprog::Gear
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

