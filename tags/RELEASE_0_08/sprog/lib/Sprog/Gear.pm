package Sprog::Gear;

use strict;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app
  machine
  id
  next
  x
  y
  msg_queue
  work_done
));


our @ISA;
use Scalar::Util qw(weaken);

sub input_type    { 'P'; }
sub output_type   { 'P'; }
sub has_input     {  return defined shift->input_type;  }
sub has_output    {  return defined shift->output_type; }
sub view_subclass { ''; }
sub no_properties {  0; }
sub title         { ''; }

sub new {
  my $class = shift;

  my $self = bless { 
    $class->defaults,
    @_,
  }, $class;

  $self->{x} = 0 unless defined($self->{x});
  $self->{y} = 0 unless defined($self->{y});
  
  $self->{app} && weaken($self->{app});
  $self->{machine} && weaken($self->{machine});
  
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


sub prime {
  my($self) = @_;

  $self->msg_queue([]) if$self->has_input; 

  return 1;
}


sub last {
  my($self) = @_;

  my $next = $self->next or return $self;
  return $next->last;
}


sub msg_in {
  my $self = shift;

  my $queue = $self->msg_queue;
  push @$queue, @{delete $self->{redo_msg_queue}} if $self->{redo_msg_queue};
  push @$queue, [ @_ ];
}


sub requeue_message_delayed {
  my $self = shift;

  #$self->{redo_msg_queue} ||= [];
  push @{$self->{redo_msg_queue}}, [ @_ ];
}


sub msg_out {
  my $self = shift;
  my $msg  = shift or return;

  my $next = $self->next or return;

  $self->machine->enable_idle_handler;
  $next->msg_in($msg => @_);
}


sub turn_once {
  my $self = shift;

  my $queue = $self->msg_queue;
  return unless @$queue;
  my $args = shift @$queue;
  my $method = shift @$args;
  if($self->can($method)) {
    $self->$method(@$args);
  }
  else {
    $self->msg_out($method => @$args);
  }
  return $self->work_done(1);
}


1;

