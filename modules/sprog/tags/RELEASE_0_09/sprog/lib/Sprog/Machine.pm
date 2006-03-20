package Sprog::Machine;

use strict;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app
  parts
  start_time
  stalled
  scheduler
));

use Scalar::Util qw(weaken);
use YAML;
use Time::HiRes qw(time);

use constant FILE_APPLICATION_ID         => 'Sprog';
use constant FILE_FORMAT_CURRENT_VERSION => 1;


sub new {
  my $class = shift;
  
  my $self = bless {
    parts => {},
    @_
  }, $class;
  weaken($self->{app});

  $self->app->factory->inject(   # set default classes if not already defined
    '/app/machine/scheduler' => 'Sprog::Machine::Scheduler',
  );

  return $self;
}


{ # closure for generating unique IDs
  my $unique_id = 1;
  sub unique_id { $unique_id++ }
}


sub expunge {
  my($self) = @_;

  my $app = $self->app;
  $app->delete_gear_by_id($_) foreach( keys %{$self->parts} );
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

  return 1;
}


sub load_from_file {
  my($self, $filename) = @_;

  my($props, $gears) = $self->_read_file($filename) or return;

  $self->_create_gears_from_file($gears);
  return 1;
}


sub _read_file {
  my($self, $filename) = @_;

  open my $in, '<', $filename
    or return $self->app->alert("Error reading $filename", "$!");

  local($/) = undef;
  my $yaml = <$in>;

  my $data = eval { YAML::Load($yaml); };
  $@ = '';

  return $self->app->alert(
    "Error reading $filename",  "Unrecognised data format"
  ) unless(defined($data));

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
    $@ = '';
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


sub running {
  my $self = shift;
  
  if(@_) {
    $self->{running} = shift;
    if($self->{running}) {
      $self->start_time(time());
      $self->app->status_message("Machine running");
    }
    else {
      my $run_time = sprintf("%4.2fs", time() - $self->start_time);
      $self->app->status_message("Machine stopped (elapsed time: $run_time)");
      if(my $sched = $self->scheduler) {
        $sched->stop;
        $self->scheduler(undef);
      }
    }
  }
  return $self->{running};
}


sub head_gear {
  my $self = shift;

  my $parts = $self->parts;
  return unless keys %$parts;  # reset the iterator
  while(my($i, $gear) = each %$parts) {
    return $gear if(!$gear->has_input);
  }
}


sub run {
  my $self = shift;

  my $head = $self->head_gear;
  return $self->app->alert("You must add an input gear") unless($head);
  return $self->app->alert("You must complete your machine with an output gear")
    if($head->last->has_output);

  my $sched = $self->scheduler(
    $self->app->factory->make_class('/app/machine/scheduler', $head)
  ) or return;

  $sched->schedule_main_loop;

  $self->app->machine_running(1);  # let the GUI know we've started
}


sub stop {
  my($self) = @_;

  $self->app->machine_running(0);
}


1;


__END__

=head1 NAME

Sprog::Machine - Data model for a Sprog application

=head1 DESCRIPTION

This class implements the data model for a sprog application.  It is a 
container for L<Sprog::Gear> classes.

When a machine is run, it creates a L<Sprog::Machine::Scheduler> instance to
handle the passing of messages between gears.

There's a bit more information in L<Sprog::help::internals>.

=head1 SEE ALSO

L<Sprog>

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


