package DummyMachine;

use strict;
use warnings;

use base qw(Sprog::Accessor);

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


sub enable_idle_handler      { 1; }
sub register_data_provider   { 1; }
sub unregister_data_provider { 1; }


1;

