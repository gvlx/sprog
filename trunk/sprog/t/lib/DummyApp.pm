package DummyApp;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  factory
  machine
  view
));


sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;

  my $factory = $self->{factory} || die "No class factory";

  $factory->inject(   # set default classes if not already defined
    '/app/machine' => 'DummyMachine',
    '/app/view'    => 'DummyView',
  );
  $self->machine( $factory->make_class('/app/machine', app => $self) );
  $self->view   ( $factory->make_class('/app/view',    app => $self) );

  return $self;
}


1;

