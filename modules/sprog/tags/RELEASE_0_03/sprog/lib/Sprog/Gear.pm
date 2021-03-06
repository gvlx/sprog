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
    x => 0,
    y => 0,
  }, $class;
  $self->{app} && weaken($self->{app});
  $self->{machine} && weaken($self->{machine});
  return $self;
}


sub declare_properties {
  my $class = shift;

  no strict 'refs';
  @{"${class}::Defaults"} = @_;

  while(@_) {
    $class->mk_accessors(shift);
    shift;
  }
}


sub defaults {
  my $class = ref($_[0]) || $_[0];

  no strict 'refs';
  return @{"${class}::Defaults"};
}

sub prime {
  my($self) = @_;

  $self->msg_queue([]) if$self->has_input; 

  return 1;
}


sub last {
  my($self) = @_;

  my $next = $self->next || return $self;
  return $next->last;
}


sub msg_in {
  my $self = shift;

  my $queue = $self->msg_queue;
  push @$queue, [ @_ ];
}


sub msg_out {
  my $self = shift;
  my $msg  = shift || return;

  my $next = $self->next || return;

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


sub line {
  my($self, $line) = @_;

  my $id = $self->id;
  warn "$id: '$line'\n";

  $self->msg_out(line  => $line);
}


sub dump {
  my($self) = @_;

  my $class = ref($self);
  print "    $class\n";
  print "        x: ", _valu($self->x), "\n";
  print "        y: ", _valu($self->y), "\n";
  my $next = $self->next;
  $next &&= $next->id;
  print "        next: ", _valu($next), "\n";
}


sub _valu { my $val = shift; defined $val ? "'$val'" : 'undef'; }

1;

