package Sprog::HelpParser;

use strict;
use warnings;

use base qw(
  Pod::Simple::Methody
);


sub new {
  my($class, $view) = @_;

  my $self = $class->SUPER::new;

  $self->{_view_} = $view;
  $self->{_tag_stack_} = [ [] ];

  $self->accept_targets('sprog-help-text');

  return $self;
}


sub start_for {
  my($self, $info) = @_; 
  $self->{_view_}->clear if $info->{target} eq 'sprog-help-text';
}


sub handle_text       { $_[0]->_emit($_[1]); }

sub start_head1       { $_[0]->_start_block(qw(head1));    }
sub start_head2       { $_[0]->_start_block(qw(head2));    }
sub start_head3       { $_[0]->_start_block(qw(head3));    }
sub start_head4       { $_[0]->_start_block(qw(head4));    }
sub start_Para        { $_[0]->_start_block(qw(para));     }
sub start_Verbatim    { $_[0]->_start_block(qw(verbatim)); }
sub start_item_text   { $_[0]->_start_block(qw(head4));    }

sub start_over_text {
  my $self = shift;

  # TODO: Handle indenting everything except the text item tag itself
  #use Data::Dumper; warn "start_over_text: " . Dumper(\@_);
}

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

sub end_head1         { $_[0]->_end_block; }
sub end_head2         { $_[0]->_end_block; }
sub end_head3         { $_[0]->_end_block; }
sub end_head4         { $_[0]->_end_block; }
sub end_Para          { $_[0]->_end_block; }
sub end_Verbatim      { $_[0]->_end_block; $_[0]->_emit("\n"); }
sub end_item_bullet   { $_[0]->_end_block; }
sub end_item_number   { $_[0]->_end_block; }
sub end_item_text     { $_[0]->_end_block; }

sub start_B           { shift->_push_tag('bold'  ); }
sub start_I           { shift->_push_tag('italic'); }
sub start_C           { shift->_push_tag('code'  ); }
sub start_F           { shift->_push_tag('code'  ); }

sub start_L {
  my($self, $args) = @_;

  $self->{_view_}->link_data($args->{type}, "$args->{to}"); # stringify target

  push @{$self->{_tag_stack_}->[-1]}, 'link';   
}

sub end_B             { shift->_pop_tag; }
sub end_I             { shift->_pop_tag; }
sub end_C             { shift->_pop_tag; }
sub end_F             { shift->_pop_tag; }
sub end_L             { shift->_pop_tag; }

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

  $self->{_view_}->add_tagged_text($text, $self->{_tag_stack_}->[-1]);
}


1;


