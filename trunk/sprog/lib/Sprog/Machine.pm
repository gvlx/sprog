package Sprog::Machine;

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
use YAML;

use constant FILE_APPLICATION_ID         => 'Sprog';
use constant FILE_FORMAT_CURRENT_VERSION => 1;


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


sub save_to_file {
  my($self, $filename) = @_;

  my @gears = ();
  foreach my $gear ( values %{$self->parts} ) {
    push @gears, $gear->serialise;
  }
  open my $out, '>', $filename
    or return $self->app->alert("Error saving file", "open($filename) - $!");

  print $out YAML::Dump([
    FILE_APPLICATION_ID,
    FILE_FORMAT_CURRENT_VERSION,
    {},          # Machine-level properties
    \@gears      # Gears and their properties
  ]);
}


sub load_from_file {
  my($self, $filename) = @_;

  my @data = $self->_read_file($filename) || return;
  $self->_create_gears_from_file(@data);
  return 1;
}


sub _read_file {
  my($self, $filename) = @_;

  open my $in, '<', $filename
    or return $self->app->alert("Error reading $filename", "$!");

  local($/) = undef;
  my $yaml = <$in>;

  my $data = YAML::Load($yaml);

  my($app_id, $file_format, $machine_data, $gear_data) = @$data;

  return $self->app->alert(
    "Unrecognised file type",  
    "Expected Application ID: " .  FILE_APPLICATION_ID . "\nGot: $app_id"
  ) if($app_id ne FILE_APPLICATION_ID);

  return $self->app->alert(
    "Unrecognised file version",  
    "Expected Format Version: " .  FILE_FORMAT_CURRENT_VERSION
      . "\nGot: $file_format"
  ) if($file_format ne FILE_FORMAT_CURRENT_VERSION);

  return($machine_data, $gear_data);
}


sub _create_gears_from_file {
  my($self, $gears) = @_;

  my $app = $self->app;

  my %map;
  foreach my $g (@$gears) {
    my $gear = $app->add_gear_at_x_y($g->{CLASS}, $g->{X}, $g->{Y});
    $map{$g->{ID}} = $gear;
    while(my($p, $v) = each %{$g->{prop}}) {
      $gear->$p($v);
    }
  }

  foreach my $g (@$gears) {
    if($g->{NEXT}) {
      my $gear = $map{$g->{ID}};
      $gear->next($map{$g->{NEXT}});
    }
  }

}


sub add_gear {
  my $self       = shift;
  my $gear_class = shift;
  
  my $gear_id = $self->unique_id;

  my $gear = eval {
    $self->app->require_class($gear_class);
    $gear_class->new( app => $self->app, machine => $self, id => $gear_id, @_ );
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
