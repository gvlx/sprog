package Pstax::Machine;

use strict;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app
  parts
  gear_train
  running
  stalled
));

use Scalar::Util qw(weaken);


sub new {
  my $class = shift;
  
  my $self = bless {
    parts => {},
    @_
  }, $class;
  $self->{app} && weaken($self->{app});
  return $self;
}


{ # closure for generating unique IDs
  my $unique_id = 1;
  sub unique_id { $unique_id++ }
}


sub add_gear {
  my($self, $gear_class) = @_;
  
  my $gear_id = $self->unique_id;

  my $gear = eval {
    $self->app->require_class($gear_class);
    $gear_class->new( app => $self->app, machine => $self, id => $gear_id );
  };
  if($@) {
    $self->app->alert("Unable to create a $gear_class object", $@);
    undef($@);
    return;
  }

  $self->parts->{$gear_id} = $gear;

  return $gear;
}


sub delete_gear_by_id {
  my($self, $id) = @_;

  my $gear = delete $self->parts->{$id};
  $self->detach_gear($gear);
}



sub detach_gear {
  my($self, $gear) = @_;

  my $parts = $self->parts;
  return unless keys %$parts;  # reset the iterator
  while(my($i, $target) = each %$parts) {
    my $next = $target->next;
    if($next  and  $next == $gear) {
      $target->next(undef);
      return;
    }
  }
}


sub head_gear {
  my $self = shift;

  my $parts = $self->parts;
  return unless keys %$parts;  # reset the iterator
  while(my($i, $gear) = each %$parts) {
    return $gear if(!$gear->has_input);
  }
}


sub build_gear_train {
  my $self = shift;

  $self->stalled(1);                 # send_data will un-stall it

  my $head = $self->head_gear;
  return $self->app->alert("You must add an input gear") unless($head);
  return $self->app->alert("You must complete your machine with an output gear")
    if($head->last->has_output);


  $self->init_data_providers;

  my @train = ();
  my $gear = $head;
  while($gear = $gear->next) {
    $gear->prime || return;
    push @train, $gear;
  }

  $head->prime || return;

  $self->gear_train([ reverse @train ]);

  $self->send_data;

  return 1;
}


sub init_data_providers { $_[0]->{providers} = {} }

sub register_data_provider {
  my($self, $gear) = @_;

  $self->{providers}->{$gear->id} = $gear;
}

sub unregister_data_provider {
  my($self, $gear) = @_;

  delete $self->{providers}->{$gear->id};
}

sub send_data {
  my($self) = @_;

  my $count = 0;
  foreach my $gear (values %{$self->{providers}}) {
    $count++;
    $gear->send_data;
  }

  return $count;
}


sub turn_one_gear {
  my $self = shift;

  return 0 unless $self->running;

  my $train = $self->gear_train;
  foreach my $gear (@$train) {
    $gear->turn_once && return 1;  # re-enable idle callback
  }
  $self->stalled(1);
  if(!$self->send_data) {  # no registered providers left
    $self->app->machine_running(0);
  }
  return 0;
}


sub enable_idle_handler {
  my($self) = @_;

  return unless $self->stalled();
  $self->app->add_idle_handler(sub { $self->turn_one_gear });
  $self->stalled(0);
}


sub stop {
  my($self) = @_;

  $self->app->machine_running(0);
}

1;
