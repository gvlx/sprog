package DummyApp;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  factory
  machine
  view
  alerts
  io_readers
));


sub new {
  my $class = shift;

  my $self = bless { @_, alerts => '', io_readers => [] }, $class;

  my $factory = $self->{factory} || die "No class factory";

  $factory->inject(   # set default classes if not already defined
    '/app/machine' => 'DummyMachine',
    '/app/view'    => 'DummyView',
  );
  $self->machine( $factory->make_class('/app/machine', app => $self) );
  $self->view   ( $factory->make_class('/app/view',    app => $self) );

  return $self;
}


sub alert {
  my($self, $alert, $detail) = @_;

  $alert  = '<undef>' unless defined($alert);
  $detail = '<undef>' unless defined($detail);
  $self->{alerts} .= "$alert\n$detail\n";
}


sub add_io_reader {
  my($self, $fh, $sub) = @_;

  push @{$self->io_readers}, $sub;
}

1;

