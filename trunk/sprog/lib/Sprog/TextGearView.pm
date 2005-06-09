package Sprog::TextGearView;

use strict;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app
));

use Scalar::Util qw(weaken);

sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;
  weaken($self->{app});

  return $self;
}





1;

