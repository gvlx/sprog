package Sprog::Gear;

use strict;

use base qw(Class::Accessor::Fast);

# TODO: remove msg_queue
__PACKAGE__->mk_accessors(qw(
  app
  machine
  meta
  title
  input_type
  output_type
  view_subclass
  no_properties
  id
  next
  x
  y
  msg_queue
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
    $class->defaults,
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


sub defaults {
  my $class = (ref($_[0]) ? ref($_[0]) : $_[0]);

  my @defaults;
  no strict 'refs';

  foreach my $c (reverse $class->class_lineage) {
    push @defaults, @{$c .'::GearDefaultProps'};
  }

  return @defaults;
}


sub class_lineage {
  my $class = shift;

  no strict 'refs';
  my @lineage = $class;
  foreach my $c (@{$class . '::ISA'}) {
    push @lineage, $c->class_lineage if($c->can('class_lineage'));
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
    prop  => { $self->defaults },
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

