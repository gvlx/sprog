package TestApp;

use strict;
use warnings;

use base qw(Sprog);

__PACKAGE__->mk_accessors(qw(
  alerts
  timed_out
));

use Sprog::ClassFactory;

sub make_test_app {
  my $class = shift;

  return make_app(               # Imported from ClassFactory.pm
    '/app'         => $class,
    '/app/machine' => 'TestMachine',
    '/app/view'    => 'DummyView',
  );

}


sub new {
  my $class = shift;

  $class->SUPER::new(@_, alerts => '', timed_out => 0);
}


sub make_test_machine {
  my $self = shift;
  
  my @gears;
  foreach my $i (0..$#_) {
    push @gears, $self->add_gear_at_x_y($_[$i], 10, $i * 10);
  }

  for(my $i = $#gears; $i > 0; $i--) {
    $gears[$i-1]->next($gears[$i]);
  }

  return @gears;
}


sub alert {
  my($self, $alert, $detail) = @_;

  $self->{alerts} ||= '';
  $alert  = '<undef>' unless defined($alert);
  $detail = '<undef>' unless defined($detail);
  $self->{alerts} .= "$alert\n$detail\n";

  return;  # callers assume no value returned
}


sub run_machine {
  my $self = shift;

  $self->alerts('');
  $self->timed_out(0);

  $self->SUPER::run_machine(@_);
  return $self->_test_return_value unless $self->machine->running;

  $self->add_timeout(2000, sub { $self->timed_out(1); $self->quit } );
  $self->run;

  return $self->_test_return_value;
}


sub _test_return_value {
  my $self = shift;

  return ($self->timed_out() ? "Machine hung, interrupted by timeout\n" : '')
         . $self->alerts;
}


sub machine_running {
  my $self = shift;

  $self->quit unless($self->SUPER::machine_running(@_));
}

1;

