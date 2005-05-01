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
sub start_item_number { $_[0]->_start_block;               }
sub start_item_text   { $_[0]->_start_block;               }

sub start_item_bullet {
  my $self = shift;
  
  $self->_start_block(qw(bullet));
  $self->_emit("\x{B7} ");
}

sub end_head1         { $_[0]->_end_block; }
sub end_head2         { $_[0]->_end_block; }
sub end_head3         { $_[0]->_end_block; }
sub end_head4         { $_[0]->_end_block; }
sub end_Para          { $_[0]->_end_block; }
sub end_Verbatim      { $_[0]->_end_block; $_[0]->_emit("\n"); }
sub end_item_bullet   { $_[0]->_end_block; $_[0]->_emit("\n"); }
sub end_item_number   { $_[0]->_end_block; $_[0]->_emit("\n"); }
sub end_item_text     { $_[0]->_end_block; $_[0]->_emit("\n"); }

sub start_B           { push @{$_[0]->{_tag_stack_}->[-1]}, 'bold';   }
sub start_I           { push @{$_[0]->{_tag_stack_}->[-1]}, 'italic'; }
sub start_C           { push @{$_[0]->{_tag_stack_}->[-1]}, 'code';   }
sub start_F           { push @{$_[0]->{_tag_stack_}->[-1]}, 'code';   }
sub start_L           { push @{$_[0]->{_tag_stack_}->[-1]}, 'link';   }

sub end_B             { pop  @{$_[0]->{_tag_stack_}->[-1]}; }
sub end_I             { pop  @{$_[0]->{_tag_stack_}->[-1]}; }
sub end_C             { pop  @{$_[0]->{_tag_stack_}->[-1]}; }
sub end_F             { pop  @{$_[0]->{_tag_stack_}->[-1]}; }
sub end_L             { pop  @{$_[0]->{_tag_stack_}->[-1]}; }

sub _start_block {
  my $self = shift;

  push @{$self->{_tag_stack_}}, [ @_ ];
}

sub _end_block {
  my $self = shift;

  pop @{$self->{_tag_stack_}};
  $self->_emit("\n");
}

sub _emit {
  my($self, $text) = @_;

  $self->{_view_}->add_tagged_text($text, $self->{_tag_stack_}->[-1]);
}


1;


