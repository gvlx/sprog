package TestApp;

use strict;
use warnings;

use base qw(Sprog);

__PACKAGE__->mk_accessors(qw(
  alerts
  timed_out
));


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

  my $last = pop @gears;
  while(@gears) {
    $gears[-1]->next($last);
    $last = pop @gears;
  }

  return $last;
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
  return unless $self->machine->running;

  $self->add_timeout(2000, sub { $self->timed_out(1); $self->quit } );
  $self->run;
}


sub machine_running {
  my $self = shift;

  $self->quit unless($self->SUPER::machine_running(@_));
}

1;

