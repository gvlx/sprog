package ParaTest;

=begin sprog-gear-metadata

  title: Para Test
  type_in: P
  type_out: P

=end sprog-gear-metadata

=cut

use base qw(
  Sprog::Mixin::InputByPara
  Sprog::Gear
);

sub para {
  my($self, $data) = @_;

  $self->msg_out(data => $data);
}


1;

