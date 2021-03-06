package Sprog::HelpParser;

use strict;
use warnings;

use base qw(
  Pod::Simple::Methody
);

use File::Spec;


sub new {
  my($class, $view) = @_;

  my $self = $class->SUPER::new;

  $self->{_view_}      = $view;
  $self->{_tag_stack_} = [ [] ];
  $self->{_indent_}    = 0;

  $self->accept_targets('sprog-help-text');

  return $self;
}


sub parse_topic {
  my($self, $topic) = @_;

  my $file = $self->_find_file($topic) or return;
  $self->parse_file($file);
}


sub _find_file {
  my($self, $topic) = @_;

  # Check for gear classes (including private gear dir) first

  my $app = $self->{_view_}->app;
  my $info = $app->geardb->gear_class_info($topic);
  return $info->{file} if($info and $info->{file});

  # Otherwise, scan @INC

  my @parts = split /::/, $topic;

  foreach my $dir (@INC) {
    my $path = File::Spec->catfile($dir, @parts);
    return "$path.pod" if -r "$path.pod";
    return "$path.pm"  if -r "$path.pm";
    $path = File::Spec->catfile($dir, 'pod', @parts);
    return "$path.pod" if -r "$path.pod";
  }

  return;
}


sub _increase_indent { $_[0]->{_indent_}++;              }
sub _decrease_indent { $_[0]->{_indent_}-- if $_[0] > 0; }


sub start_for {
  my($self, $info) = @_; 
  $self->{_view_}->clear if $info->{target} eq ':sprog-help-text';
}


sub handle_text       { $_[0]->_emit($_[1]); }

sub start_head1       { $_[0]->_start_block(qw(head1));    }
sub start_head2       { $_[0]->_start_block(qw(head2));    }
sub start_head3       { $_[0]->_start_block(qw(head3));    }
sub start_head4       { $_[0]->_start_block(qw(head4));    }
sub start_Para        { $_[0]->_start_block(qw(para));     }
sub start_Verbatim    { $_[0]->_start_block(qw(verbatim)); }
sub start_over_bullet { $_[0]->_increase_indent;           }
sub start_over_number { $_[0]->_increase_indent;           }
sub start_over_text   { $_[0]->_increase_indent;           }

sub start_item_bullet {
  my $self = shift;

  $self->_start_block(qw(bullet));
  $self->_emit("\x{B7} ");
}

sub start_item_number {
  my($self, $data) = @_;

  $self->_start_block(qw(bullet));
  $self->_emit($data->{number} . '. ');
}

sub start_item_text {
  my $self = shift;
  
  $self->_decrease_indent;
  $self->_start_block(qw(head4));
}

sub end_head1         { $_[0]->_end_block; }
sub end_head2         { $_[0]->_end_block; }
sub end_head3         { $_[0]->_end_block; }
sub end_head4         { $_[0]->_end_block; }
sub end_Para          { $_[0]->_end_block; }
sub end_Verbatim      { $_[0]->_end_block; $_[0]->_emit("\n"); }
sub end_over_bullet   { $_[0]->_decrease_indent; }
sub end_over_number   { $_[0]->_decrease_indent; }
sub end_over_text     { $_[0]->_decrease_indent; }
sub end_item_bullet   { $_[0]->_end_block; }
sub end_item_number   { $_[0]->_end_block; }
sub end_item_text     { $_[0]->_end_block; $_[0]->_increase_indent; }

sub start_B           { shift->_push_tag('bold'  ); }
sub start_I           { shift->_push_tag('italic'); }
sub start_C           { shift->_push_tag('code'  ); }
sub start_F           { shift->_push_tag('code'  ); }

sub start_L {
  my($self, $args) = @_;

  return unless $args->{to};

  $self->{_view_}->link_data($args->{type}, "$args->{to}"); # stringify target

  push @{$self->{_tag_stack_}->[-1]}, 'link';   
}

sub end_B             { shift->_pop_tag; }
sub end_I             { shift->_pop_tag; }
sub end_C             { shift->_pop_tag; }
sub end_F             { shift->_pop_tag; }

sub end_L {
  my $self = shift;
  $self->_pop_tag if $self->{_tag_stack_}->[-1]->[-1] eq 'link';
}

sub _start_block {
  my $self = shift;

  push @{$self->{_tag_stack_}}, [ @_ ];
}

sub _end_block {
  my $self = shift;

  pop @{$self->{_tag_stack_}};
  $self->_emit("\n");
}

sub _push_tag {
  my($self, $tag) = @_;

  push @{$self->{_tag_stack_}->[-1]}, $tag;
}

sub _pop_tag {
  my($self, $tag) = @_;

  pop @{$self->{_tag_stack_}->[-1]};
}

sub _emit {
  my($self, $text) = @_;

  $self->{_view_}->add_tagged_text(
    $text, $self->{_indent_}, $self->{_tag_stack_}->[-1]
  );
}


1;


