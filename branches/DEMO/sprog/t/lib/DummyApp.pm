package DummyApp;

use strict;
use warnings;

use base qw(Sprog::Accessor);

__PACKAGE__->mk_accessors(qw(
  factory
  geardb
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
    '/app/geardb'  => 'Sprog::GearMetadata',
    '/app/machine' => 'DummyMachine',
    '/app/view'    => 'DummyView',
  );
  $self->geardb ( $factory->load_class('/app/geardb'               ) );
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

sub stop_machine     { return; }
sub update_gear_view { return; }

1;


=head1 NAME

DummyApp - For testing porpoises

=head1 DESCRIPTION

The POD in this file is for testing L<Sprog::HelpParser>.  It serves no other
purpose.

Please  I<ignore>  it.

=head2 Options

=over 4

=item *

a B<Bold> word

=item *

a C<Code> word

=back

  Verbatim  Text

=cut
