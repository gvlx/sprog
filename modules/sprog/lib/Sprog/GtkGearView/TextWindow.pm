package Sprog::GtkGearView::TextWindow;

use strict;

use base qw(Sprog::GtkGearView);

__PACKAGE__->mk_accessors(qw(
  gear_win
  text_view
  text_buffer
));

use Glib qw(TRUE FALSE);


sub add_data {
  my($self, $data) = @_;
  
  $self->create_window unless $self->gear_win;

  my $text_buffer = $self->text_buffer;
  my $end = $text_buffer->get_end_iter;
  $text_buffer->insert ($end, $data);
  $self->text_view->scroll_to_iter($end, 0, 0, 0, 0) if($self->gear->auto_scroll);

  $self->show_window unless $self->gear_win->visible;
}


sub create_window {
  my $self = shift;

  my $app_win = $self->app->view->app_win;

  my $dialog = Gtk2::Dialog->new(
    "Sprog Text Output",
    $app_win,
    [qw/destroy-with-parent no-separator/],
  );
  $self->gear_win($dialog);
  $dialog->resize(480, 360);
  $dialog->signal_connect('delete_event' => sub { $dialog->hide; return 1 });

  my $scrolled_window = Gtk2::ScrolledWindow->new;
  $scrolled_window->set_policy('automatic', 'automatic');
  $scrolled_window->set_shadow_type('in');

  my $text_view = Gtk2::TextView->new;
  $self->text_view($text_view);

  my $text_buffer = Gtk2::TextBuffer->new(undef);
  $self->text_buffer($text_buffer);
  $text_buffer->delete($text_buffer->get_bounds);

  $text_view->set_buffer($text_buffer);
  $text_view->set_editable(FALSE);
  $text_view->set_cursor_visible(FALSE);

  $text_view->set_wrap_mode('none');

  $scrolled_window->add($text_view);

  $dialog->vbox->add($scrolled_window);

  my $clear_button = Gtk2::Button->new("_Clear");
  $clear_button->signal_connect( "clicked" => sub { $self->clear; } );
  $dialog->add_action_widget($clear_button, 'none');

  my $hide_button = Gtk2::Button->new("_Hide");
  $hide_button->signal_connect( "clicked" => sub { $dialog->hide; } );
  $dialog->add_action_widget($hide_button, 'none');

  $dialog->signal_connect( "key_press_event" => sub { $self->on_key_press(@_); } );

  $dialog->vbox->show_all;
  $self->show_window;
}


sub clear {
  my $self = shift;

  my $text_buffer = $self->text_buffer || return;  # not created yet
  $text_buffer->set_text('');
}


sub context_menu_entries {
  my $self = shift;

  my $menu = $self->SUPER::context_menu_entries;

  my $gear_win = $self->gear_win;
  my $visible = $gear_win && $gear_win->visible;

  push @$menu, {
      title    => ($visible ? 'Hide' : 'Show') . ' text window',
      callback => sub { $self->toggle_window_visibility },
      disabled => FALSE,
  };

  return $menu;
}

sub toggle_window_visibility {
  my $self = shift;

  my $gear_win = $self->gear_win;
  if($gear_win) {
    $gear_win->visible ? $gear_win->hide : $self->show_window;
  }
  else {
    $self->create_window;
  }
}


sub show_window {
  my $self = shift;

  my $gear_win  = $self->gear_win;
  my $font_desc = Gtk2::Pango::FontDescription->from_string(
    $self->view->text_window_font
  );
  $self->text_view->modify_font($font_desc);

  $gear_win->show;
}


sub on_key_press {
  my($self, $dialog, $event) = @_;

  return FALSE unless($event->keyval == $Gtk2::Gdk::Keysyms{Escape});

  $dialog->hide;
  return TRUE;
}


1;
