package Sprog::GtkView::HelpViewer;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2::GladeXML;
use Gtk2::Pango;
use File::Spec;

use base qw(
  Pod::Simple::Methody
  Class::Accessor::Fast
);

__PACKAGE__->mk_accessors(qw(
  helpwin textview buffer
));


sub show_help {
  my($class, $topic) = @_;

  my $self = $class->new;

  $self->set_topic($topic);
}


sub new { return shift->SUPER::new->_init; }


sub _init {
  my $self = shift;

  my $glade_file = __FILE__;
  $glade_file = '/home/grant/projects/sf/sprog/glade/help.glade';

  my $gladexml = Gtk2::GladeXML->new($glade_file);

  $gladexml->signal_autoconnect(
    sub { $self->autoconnect(@_) }
  );

  my $window = $self->helpwin($gladexml->get_widget('helpwin'));
  $window->resize(550, 500);
$window->signal_connect(delete_event => sub { Gtk2->main_quit });

  my $textview = $self->textview($gladexml->get_widget('textview'));
  $textview->set_editable(FALSE);
  $textview->set_cursor_visible(FALSE);
  my $font_desc = Gtk2::Pango::FontDescription->from_string ("Serif 10");
  $textview->modify_font ($font_desc);
  $textview->set_wrap_mode('word');
  $textview->set_left_margin(6);
  $textview->set_right_margin(4);

  my $buffer = $self->buffer($self->textview->get_buffer);

  $self->_init_tags($buffer, $font_desc->get_size);

  return $self;
}


sub _init_tags {
  my($self, $buffer, $size) = @_;

  $buffer->create_tag('head1',
    family             => 'Sans',
    weight             => PANGO_WEIGHT_BOLD,
    size               => $size * 1.6,
    pixels_above_lines => 12,
    pixels_below_lines => 4,
  );

  $buffer->create_tag('head2',
    family             => 'Sans',
    weight             => PANGO_WEIGHT_BOLD,
    size               => $size * 1.4,
    pixels_above_lines => 4,
    pixels_below_lines => 2,
  );

  $buffer->create_tag('head3',
    family             => 'Sans',
    weight             => PANGO_WEIGHT_BOLD,
    size               => $size * 1.2,
    pixels_above_lines => 6,
    pixels_below_lines => 2,
  );

  $buffer->create_tag('head4',
    family             => 'Sans',
    weight             => PANGO_WEIGHT_BOLD,
    size               => $size,
    pixels_above_lines => 6,
    pixels_below_lines => 2,
  );

  $buffer->create_tag('para',
    pixels_below_lines => 8,
  );

  $buffer->create_tag('bullet',
    left_margin        => 20,
    pixels_above_lines => 2,
    pixels_below_lines => 2,
  );

  $buffer->create_tag('verbatim',
    wrap_mode          => 'none',
    family             => 'monospace',
    size               => $size,
  );

  $buffer->create_tag('bold',
    weight             => PANGO_WEIGHT_BOLD,
  );

  $buffer->create_tag('italic',
    style              => 'italic'
  );

  $buffer->create_tag('code',
    family             => 'monospace',
  );

  $buffer->create_tag('link',
    underline          => 'single',
    foreground         => 'blue',
  );

}


sub autoconnect {
  my($self, $method, $widget, $signal) = @_;

  die __PACKAGE__ . " has no $method method"
    unless $self->can($method);
    
  $widget->signal_connect(
    $signal => sub { $self->$method(@_) }
  );
}


sub set_topic {
  my($self, $topic) = @_;

  $self->clear;

  my $file = $self->_find_file($topic) or return;
  $self->{tag_stack} = [];
  $self->parse_file($file);
}

sub clear {
  my $self = shift;

  $self->buffer->set_text('');
}


sub _find_file {
  my($self, $topic) = @_;

  my @parts = split /::/, $topic;

  foreach my $dir (@INC) {
    my $path = File::Spec->catfile($dir, @parts);
    return "$path.pod" if -r "$path.pod";
    return "$path.pm"  if -r "$path.pm";
  }
warn "'$topic' not found\n";

  return;
}

########################### GUI Event Handlers ###############################

sub on_close_activated {
  my $self = shift;

  $self->helpwin->destroy;
}


sub on_find_activated {
  my $self = shift;
}


sub on_back_activated {
  my $self = shift;
}


sub on_forward_activated {
  my $self = shift;
}


sub on_home_activated {
  my $self = shift;
}


########################### POD Event Handlers ###############################

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

sub start_B           { push @{$_[0]->{tag_stack}->[-1]}, 'bold';   }
sub start_I           { push @{$_[0]->{tag_stack}->[-1]}, 'italic'; }
sub start_C           { push @{$_[0]->{tag_stack}->[-1]}, 'code';   }
sub start_F           { push @{$_[0]->{tag_stack}->[-1]}, 'code';   }
sub start_L           { push @{$_[0]->{tag_stack}->[-1]}, 'link';   }

sub end_B             { pop  @{$_[0]->{tag_stack}->[-1]}; }
sub end_I             { pop  @{$_[0]->{tag_stack}->[-1]}; }
sub end_C             { pop  @{$_[0]->{tag_stack}->[-1]}; }
sub end_F             { pop  @{$_[0]->{tag_stack}->[-1]}; }
sub end_L             { pop  @{$_[0]->{tag_stack}->[-1]}; }

sub _start_block {
  my $self = shift;

  push @{$self->{tag_stack}}, [ @_ ];
}

sub _end_block {
  my $self = shift;

  pop @{$self->{tag_stack}};
  $self->_emit("\n");
}

sub _emit {
  my($self, $text) = @_;

  my $buffer = $self->buffer;

  my $iter = $buffer->get_end_iter;
  my $tags = $self->{tag_stack}->[-1];
  $buffer->insert_with_tags_by_name($iter, $text, @$tags);
}

1;

