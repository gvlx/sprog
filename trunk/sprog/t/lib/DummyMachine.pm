package DummyMachine;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app
));

use Scalar::Util qw(weaken);


sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;

  $self->{app} && weaken($self->{app});

  return $self;
}


1;
