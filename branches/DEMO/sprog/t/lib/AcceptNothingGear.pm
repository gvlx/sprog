package AcceptNothingGear;

=begin sprog-gear-metadata

  title: Accept Nothing
  type_in: P
  type_out: _

=end sprog-gear-metadata

=cut

use base qw(Sprog::Gear);

sub engage {
  my $self = shift;

  return $self->app->alert('I will not accept input!');
}

1;
