package TestApp;

use strict;
use warnings;

use base qw(Sprog);

__PACKAGE__->mk_accessors(qw(
  auto_quit
  alerts
  timed_out
  sequence_queue
));

use Glib qw(TRUE FALSE);
use Sprog::ClassFactory;

sub make_test_app {
  my $class = shift;

  return make_app(               # Imported from ClassFactory.pm
    '/app'         => $class,
    '/app/machine' => 'TestMachine',
    '/app/view'    => 'DummyView',
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

  $class->SUPER::new(@_, alerts => '', timed_out => 0);
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

  $self->{alerts} ||= '';
  $alert  = '<undef>' unless defined($alert);
  $detail = '<undef>' unless defined($detail);
  $self->{alerts} .= "$alert\n$detail\n";

  return;  # callers assume no value returned
}


sub run_machine {
  my $self = shift;

  $self->auto_quit(1);
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

  $self->quit if(!$self->SUPER::machine_running(@_)  and  $self->auto_quit);
}


sub run_sequence {
  my $self = shift;

  $self->auto_quit(0);
  $self->alerts('');
  $self->timed_out(0);

  $self->sequence_queue([ @_, sub { $self->quit; } ]);

  $self->add_timeout(5000, sub { $self->timed_out(1); $self->quit } );
  $self->add_idle_handler( sub { $self->_sequence_step } );
  $self->run;

  return $self->_test_return_value;
}


sub _sequence_step {
  my $self = shift;

  my $queue = $self->sequence_queue;

  return FALSE unless(@$queue);    # No milk today thanks

  my $step = shift @$queue;
  $step->();

  return TRUE;                     # Thank you, please call again
}

1;

