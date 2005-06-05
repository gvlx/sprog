package Sprog::Machine;

use strict;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app
  _parts
  _start_time
  _scheduler
));

use Scalar::Util qw(weaken);
use YAML;
use Time::HiRes qw(time);

use constant FILE_APPLICATION_ID         => 'Sprog';
use constant FILE_FORMAT_CURRENT_VERSION => 1;


sub new {
  my $class = shift;
  
  my $self = bless {
    _parts => {},
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
  sub _unique_id { $unique_id++ }
}


sub expunge {
  my($self) = @_;

  my $app = $self->app;
  $app->delete_gear_by_id($_) foreach( keys %{$self->_parts} );
}


sub save_to_file {
  my($self, $filename) = @_;

  my @gears = ();
  foreach my $gear ( values %{$self->_parts} ) {
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
  
  my $gear_id = $self->_unique_id;

  my $gear = eval {
    $self->app->require_class($gear_class);
    $gear_class->new( app => $self->app, machine => $self, id => $gear_id, @_ );
  };
  if($@) {
    $self->app->alert("Unable to create a $gear_class object", $@);
    $@ = '';
    return;
  }

  $self->_parts->{$gear_id} = $gear;

  return $gear;
}


sub delete_gear_by_id {
  my($self, $id) = @_;

  my $gear = delete $self->_parts->{$id};
  $self->detach_gear($gear);
}



sub detach_gear {
  my($self, $gear) = @_;

  my $parts = $self->_parts;
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
      $self->_start_time(time());
      $self->app->status_message("Machine running");
    }
    else {
      my $run_time = sprintf("%4.2fs", time() - $self->_start_time);
      $self->app->status_message("Machine stopped (elapsed time: $run_time)");
      if(my $sched = $self->_scheduler) {
        $sched->stop;
        $self->_scheduler(undef);
      }
    }
  }
  return $self->{running};
}


sub head_gear {
  my $self = shift;

  my $parts = $self->_parts;
  return unless keys %$parts;  # reset the iterator
  while(my($i, $gear) = each %$parts) {
    return $gear if(!$gear->has_input);
  }
}


sub run {
  my $self = shift;

  my $head = $self->head_gear;
  return $self->app->alert("You must add an input gear") unless($head);
  my $last = $head->last;
  return $last->alert("You must complete your machine with an output gear")
    if($last->has_output);

  my $sched = $self->_scheduler(
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

This class implements the data model for a Sprog application.  It is a 
container for L<Sprog::Gear> classes.

When a machine is run, it creates a L<Sprog::Machine::Scheduler> instance to
handle the passing of messages between gears.

=head1 CLASS METHODS

=head2 new ( arguments )

Constructor.  This method is called by the L<Sprog> application class during
app startup.

=head1 INSTANCE METHODS

=head2 add_gear ( gear_class, arguments )

Adds a gear to the workspace.  Usually called from the application's
C<add_gear_at_x_y> method.  Returns a reference to the gear on success.  Fires
an alert message and returns undef on error.

=head2 app

Returns a reference to the Sprog application object.

=head2 delete_gear_by_id ( id )

Removes the specified gear from the machine.

=head2 detach_gear ( gear )

Breaks connection between the supplied gear and the gear feeding into it.
This is used for example when dragging gears to pull a machine apart.

=head2 expunge ( )

Removes all gears from the machine in such a way that the gui components
disappear too.

=head2 head_gear ( )

Returns a reference to the first gear that has no input connector.

=head2 load_from_file ( filename )

Reads the specified file, verifies file format and version information in the
header and then instantiates each of the gears described in the file as well
as the interconnections between them.

=head2 run ( )

Called by the app object to instantiate a scheduler and set it runnning.

=head2 running ( boolean )

Get/set the flag to indicate the machine is running.

=head2 save_to_file ( filename )

Serialises each of the gears and their interconnections to the named file.

=head2 stop ( )

Called by the app to stop a running machine.

=head1 SEE ALSO

L<Sprog>

L<Sprog::help::internals> has more information about the inner workings of 
Sprog.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


