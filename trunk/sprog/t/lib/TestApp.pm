package TestApp;

use strict;
use warnings;

use base qw(Sprog);

__PACKAGE__->mk_accessors(qw(
  quit_on_stop
  alerts
  intercept_alerts
  timed_out
  sequence_queue
  confirm_yes_no_handler
));

use Glib qw(TRUE FALSE);
use Sprog::ClassFactory;


sub make_test_app {
  my $class = shift;

  return make_app(               # Imported from ClassFactory.pm
    '/app'           => $class,
    '/app/machine'   => 'TestMachine',
    '/app/eventloop' => 'Sprog::GlibEventLoop',
    '/app/view'      => 'DummyView',
  );
}

sub make_gtk_app {
  my $class = shift;

  return make_app(               # Imported from ClassFactory.pm
    '/app'         => $class,
    '/app/machine' => 'TestMachine',
    '/app/view'    => 'TestView',
  );

}


sub new {
  my $class = shift;

  $class->SUPER::new(@_, alerts => '', timed_out => 0, intercept_alerts => 1);
}


sub make_test_machine {
  my $self = shift;
  
  my @gears;
  foreach my $i (0..$#_) {
    my $new = $self->add_gear_at_x_y($_[$i], 10, $i * 10) or return;
    push @gears, $new;
  }

  for(my $i = $#gears; $i > 0; $i--) {
    $gears[$i-1]->next($gears[$i]);
  }

  return @gears;
}


sub alert {
  my($self, $alert, $detail) = @_;

  return $self->SUPER::alert($alert, $detail)
    if(!$self->intercept_alerts);

  $self->{alerts} ||= '';
  $alert  = '<undef>' unless defined($alert);
  $detail = '<undef>' unless defined($detail);
  $self->{alerts} .= "$alert\n$detail\n";

  return;  # callers assume no value returned
}


sub test_run_machine {
  my $self = shift;

  $self->quit_on_stop(1);
  $self->alerts('');
  $self->timed_out(0);

  $self->SUPER::run_machine(@_);
  return $self->alerts unless $self->machine->running;

  $self->add_timeout(4000, sub { $self->timed_out(1); $self->quit; } );
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

  my $running = $self->SUPER::machine_running(@_);
  $self->quit if(!$running  and  $self->quit_on_stop);

  return $running;
}


sub run_sequence {
  my $self = shift;

  $self->quit_on_stop(0);
  $self->alerts('');
  $self->timed_out(0);

  $self->sequence_queue([ @_, sub { $self->quit; } ]);

  $self->add_timeout(15000, sub { $self->timed_out(1); $self->quit } );
  $self->add_idle_handler( sub { $self->_sequence_step } );
  $self->run;

  return $self->_test_return_value;
}


sub _sequence_step {
  my $self = shift;

  my $queue = $self->sequence_queue;

  return FALSE unless(@$queue);

  my $step = shift @$queue;
  if(ref($step)) {
    $step->();
    $self->add_idle_handler( sub { $self->_sequence_step } );
  }
  else {
    $self->add_timeout($step, sub { $self->_sequence_step } );
  }
  return FALSE;
}


sub confirm_yes_no {
  my $self = shift;

  my $handler = $self->confirm_yes_no_handler or return;
  return $handler->(@_);
}

1;

