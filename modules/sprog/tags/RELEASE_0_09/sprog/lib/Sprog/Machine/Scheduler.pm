package Sprog::Machine::Scheduler;

use strict;
use warnings;

use Scalar::Util qw(weaken);

sub new {
  my($class, $gear) = @_;
  
  my $self = bless { app => $gear->app }, $class;
  weaken($self->{app});

  return $self->_build_gear_train($gear);
}


sub schedule_main_loop {
  my $self = shift;

  return if $self->{idle_tag};

  $self->{idle_tag} = $self->{app}->add_idle_handler(
    sub { $self->main_loop; }
  );
}


sub stop {
  my $self = shift;

  foreach my $gear (values %{$self->{gear_by_id}}) {
    $gear->stop;
  }
  %$self = ();
}


sub _build_gear_train {
  my($self, $gear) = @_;

  my $gear_train = $self->{gear_train} = [];
  my $gear_by_id = $self->{gear_by_id} = {};
  my $prev_id    = $self->{prev_id}    = {};
  my $next_id    = $self->{next_id}    = {};
  my $msg_queue  = $self->{msg_queue}  = {};
  my $redo_queue = $self->{redo_queue} = {};
  my $providers  = $self->{providers}  = [];

  my $last_id = undef;
  while($gear) {
    my $id = $gear->id;
    push @$gear_train, $id;
    $gear_by_id->{$id} = $gear;
    $prev_id->{$id} = $last_id  if $last_id;
    my $next = $gear->next;
    $next_id->{$id} = $next->id if $next;
    push @$providers, $id if $gear->can('send_data');
    $last_id = $id;
    $gear = $next;
  }

  foreach my $id (reverse @$gear_train) {
    my $gear = $gear_by_id->{$id};
    $msg_queue->{$id}  = [] if $gear->has_input;
    $redo_queue->{$id} = [] if $gear->has_input;
    $gear->scheduler($self);
    $gear->engage or return;
  }

  return $self;
}


sub main_loop {
  my $self = shift;

  my $delivered = 0;
  my $sleepers  = 0;
  my $train     = $self->{gear_train};


  # Attempt delivery for each gear from last to first
  
  my $i = $#$train;
  while($i >= 0) {
    my $id   = $train->[$i];
    my $gear = $self->{gear_by_id}->{$id};
    if($gear->sleeping) {
      $sleepers++;
      next;
    }

    # Deliver all messages to this gear

    my $queue = $self->{msg_queue}->{$id} or next;
    while(@$queue) {
      my $msg = shift @$queue;
      my $method = shift @$msg;
      if(my $sub = $gear->can($method)) {
        $sub->($gear, @$msg);
      }
      else {
        $self->msg_from($id, $method, @$msg);
      }
      $gear->work_done(1);
      $delivered++;
    }
  }
  continue {
    $i--;
  }
  return 1 if $delivered;


  # No messages were delivered so the idle handler is no longer required

  delete $self->{idle_tag};

  # Remove spent gears from head of train

  while(@$train) {
    my $gear = $self->{gear_by_id}->{$train->[0]};
    last if($gear->can('send_data') or $gear->sleeping);
    $self->disengage($train->[0]);
  }

  # Stop machine if all gears disengaged

  if(!@$train) {
    my $app = $self->{app} or return 0;
    $app->machine_running(0);
    return 0;
  }

  # Or, ask providers to send more data

  if(!$sleepers) {                     # no gears with events pending
    foreach my $id (@{$self->{providers}}) {
      $self->{gear_by_id}->{$id}->send_data;
    }
  }

  return 0;
}


sub msg_from {
  my $self   = shift;
  my $src_id = shift;

  my $next_id = $self->{next_id}->{$src_id}    or return;
  my $queue   = $self->{msg_queue}->{$next_id} or return;

  my $redo_queue = $self->{redo_queue}->{$next_id};
  if(@$redo_queue) {
    push @$queue, @$redo_queue;
    @$redo_queue = ();
  }
  push @$queue, [ @_ ];

  $self->schedule_main_loop unless $self->{idle_tag};
}


sub requeue_message_delayed {
  my $self   = shift;
  my $src_id = shift;

  my $msg_queue  = $self->{msg_queue}->{$src_id}  or return;
  my $redo_queue = $self->{redo_queue}->{$src_id} or return;
  push @$redo_queue, [ @_ ], @$msg_queue;
  @$msg_queue = ();
}


sub msg_queue {
  my $self   = shift;
  my $src_id = shift;

  return $self->{msg_queue}->{$src_id};
}


sub disengage {
  my($self, $id) = @_;

  while($id) {
    $self->msg_from($id, 'no_more_data') if $self->{next_id}->{$id};

    my $gear = delete $self->{gear_by_id}->{$id} or return;

    @{$self->{gear_train}} = grep($_ != $id, @{$self->{gear_train}});
    @{$self->{providers}}  = grep($_ != $id, @{$self->{providers}});

    delete $self->{next_id}->{$id};

    delete $self->{msg_queue}->{$id};
    $gear->msg_queue(undef);

    $id = delete $self->{prev_id}->{$id};
  }

}

1;


__END__

=head1 NAME

Sprog::Machine::Scheduler - runs a Sprog machine

=head1 SYNOPSIS

  my $sched = Sprog::Machine::Scheduler->new($head_gear) or return;

  $sched->schedule_main_loop;

=head1 DESCRIPTION

The scheduler is used by a L<Sprog::Machine> to handle the messy details of
running a machine.  The inner workings of the scheduler are discussed in some
detail in L<Sprog::help::scheduler>.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut

