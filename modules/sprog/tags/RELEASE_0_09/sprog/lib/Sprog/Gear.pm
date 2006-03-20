package Sprog::Gear;

use strict;

use base qw(Class::Accessor::Fast);

# TODO: remove msg_queue
__PACKAGE__->mk_accessors(qw(
  app
  machine
  title
  input_type
  output_type
  view_subclass
  no_properties
  id
  next
  x
  y
  work_done
  sleeping
));


our @ISA;
use Scalar::Util qw(weaken);

sub has_input     { return defined shift->input_type;  }
sub has_output    { return defined shift->output_type; }
sub alert         { shift->app->alert(@_);             }

sub new {
  my $class = shift;

  my $self = bless { 
    $class->_defaults,
    @_,
  }, $class;
  
  weaken($self->{app});
  weaken($self->{machine});

  my $meta = $self->{app}->geardb->gear_class_info($class)
    or die "Could not find sprog-gear-metadata for $class";

  $self->{title}         = $meta->title;
  $self->{input_type}    = $meta->type_in  eq '_' ? undef : $meta->type_in;
  $self->{output_type}   = $meta->type_out eq '_' ? undef : $meta->type_out;
  $self->{no_properties} = $meta->no_properties || 0;
  $self->{view_subclass} = $meta->view_subclass || '';

  $self->{x} = 0 unless defined($self->{x});
  $self->{y} = 0 unless defined($self->{y});
  
  return $self;
}


sub declare_properties {
  my $class = shift;

  no strict 'refs';
  @{"${class}::GearDefaultProps"} = @_;

  while(@_) {
    $class->mk_accessors(shift);
    shift;
  }
}


sub _defaults {
  my $class = (ref($_[0]) ? ref($_[0]) : $_[0]);

  my @defaults;
  no strict 'refs';

  foreach my $c (reverse $class->_class_lineage) {
    push @defaults, @{$c .'::GearDefaultProps'};
  }

  return @defaults;
}


sub _class_lineage {
  my $class = shift;

  no strict 'refs';
  my @lineage = $class;
  foreach my $c (@{$class . '::ISA'}) {
    push @lineage, $c->_class_lineage if($c->can('_class_lineage'));
  }
  return @lineage
}


sub serialise {
  my($self) = @_;

  my $next = $self->next;
  my %data = (
    CLASS => ref($self),
    ID    => $self->id,
    NEXT  => ($next ? $next->id : undef),
    X     => $self->x,
    Y     => $self->y,
    prop  => { $self->_defaults },
  );

  foreach my $property ( keys %{$data{prop}} ) {
    $data{prop}->{$property} = $self->$property;
  }

  return \%data;
}


sub last {
  my($self) = @_;

  my $next = $self->next or return $self;
  return $next->last;
}


sub requeue_message_delayed {
  my $self = shift;

  $self->scheduler->requeue_message_delayed($self->id, @_);
}


sub msg_out {
  my $self = shift;

  my $sched = $self->scheduler or return;
  $sched->msg_from($self->id, @_);
}


sub msg_queue {
  my $self = shift;

  my $sched = $self->scheduler or return;
  $sched->msg_queue($self->id);
}


sub scheduler {
  my $self = shift;

  if(@_) {
    $self->{scheduler} = shift;
    weaken $self->{scheduler};
  }

  return $self->{scheduler};
}


sub engage { 1; }

sub disengage {
  my $self = shift;
  
  my $sched = $self->scheduler or return;
  $sched->disengage($self->id);
}

sub no_more_data { shift->disengage; }

sub stop { return; }  # default is a NOP

1;


__END__

=head1 NAME

Sprog::Gear - Base class for Sprog gears

=head1 SYNOPSIS

  use base qw(Sprog::Gear);

  __PACKAGE__->declare_properties(
    filename   =>  '',
  );

=head1 DESCRIPTION

This is the base class which all Sprog gear classes should inherit from.  It
provides default behaviours as described below:

=head1 CLASS METHODS

=head2 new ( arguments )

The constructor.  Creates a gear object and initialises it from the supplied
arguments as well as from the gear metadata section (see:
L<Sprog::GearMetadata>).

=head2 declare_properties ( name => default ... )

Defines property names and default values.  Usually called in the gear class
as shown in the synopsis above.

=head1 INSTANCE METHODS

=head2 alert ( message, detail )

Requests the main application window to pop up a message dialog to display
the alert message and optional extra detail.

=head2 app ( )

Returns a reference to the L<Sprog> application object.

=head2 disengage ( )

A gear would call this method to signal to the scheduler that it is finished
and will be sending no more messages.

=head2 engage ( )

The scheduler will call this method on each gear as it prepares to run the
machine.  A gear class should override this method to do any necessary
initialisation and then either return a false value if initialisation failed,
or call C<SUPER::engage>

=head2 has_input ( )

Returns true if the gear has an input connector.

=head2 has_output  ( )

Returns true if the gear has an output connector.

=head2 id ( )

An integer which uniquely identifies the gear.

=head2 input_type ( )

Returns a single character (currently 'P', 'A' or 'H') indicating the type of
input connector or '_' if the gear has no input connector.  Populated
automatically from the gear metadata.

=head2 last ( )

Returns a reference to the last gear in the chain - which may be the current
gear.

=head2 machine ( )

Returns a reference to the L<Sprog::Machine> object.

=head2 msg_out ( msg_name => arguments )

Send a message to the next gear.

=head2 msg_queue ( )

Returns a reference to the array of waiting messages.  Useful for peeking to
see what's coming up.

=head2 next ( )

Returns a reference to the next gear.

=head2 no_more_data ( )

The scheduler will call this method when the preceding gear has disengaged.
The default implementation will disengage the current gear.

=head2 no_properties ( )

Returns true if the gear has no user-configurable properties (and therefore the
properties option should be greyed out on the gear menu).

=head2 output_type ( )

Returns a single character (currently 'P', 'A' or 'H') indicating the type of
output connector or '_' if the gear has no output connector.  Populated
automatically from the gear metadata.

=head2 requeue_message_delayed ( msg_name => arguments )

Gives a message back to the scheduler and asks it to re-deliver the message
when the next message arrives.  Useful for reassembing fragmented data.

=head2 scheduler ( )

Returns a reference to the scheduler object - undef if the machine is not
running.

=head2 serialise ( )

Called when the machine is saved to a file.  The default implementation returns
a reference to a hash containing only those property values which would be
required to reconstruct the object.  The machine class will serialise that
hashref using whatever means it sees fit (currently YAML).

=head2 sleeping ( boolean )

A gear will set this flag to indicate that it is currently sleeping (eg:
waiting for an IO event).  The scheduler will not attempt to deliver any
messages to it (or remove it from the machine) until it wakes up.

=head2 stop ( )

Called by the scheduler when the machine is stopped - gives gears a chance to
release resources (eg: close files).

=head2 title ( )

Called by the gear view class to determine what label to display on the gear.
Populated automatically from the gear metadata.

=head2 view_subclass ( )

Returns the name of the class which will handle the user interface.  Populated
automatically from the gear metadata.

=head2 work_done ( boolean )

Used to tell the gear view class to indicate visually that the gear is working
(a cog is turned).  The scheuler will set this flag when it delivers a message.
The gear view will reset it when it indicates work done.  The gear class itself
will ignore it.

=head2 x ( )

The X position of the gear on the workspace.

=head2 y ( )

The Y position of the gear on the workspace.

=head1 SEE ALSO

Sprog gears exist within a L<Sprog::Machine>, which in turn provides the data
model for a L<Sprog> application.

More information for developers is available in
L<gear internals|Sprog::help::gear_internals>.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


