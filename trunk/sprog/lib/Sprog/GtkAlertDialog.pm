package Pstax::GtkAlertDialog;

use strict;

use Glib qw(TRUE FALSE);


sub new {
  my $class = shift;
  return bless { @_ }, $class;
}


sub invoke {
  my($class, $parent, $message, $detail) = @_;

  my $self = $class->new;

  my $dialog = $self->build_dialog($parent, $message, $detail);

  my $return;
  while(!$return or $return eq 'none') {
    $return = $dialog->run;
  }

  $dialog->destroy;
}


sub build_dialog {
  my($self, $parent, $message, $detail) = @_;

  my $dialog = Gtk2::Dialog->new(
    "Warning",
    $parent,
    [qw/modal destroy-with-parent no-separator/],
  );

  my $box = Gtk2::HBox->new(FALSE, 10);

  my $icon = Gtk2::Image->new_from_stock ('gtk-dialog-warning', 'dialog');
  $box->pack_start($icon, FALSE, FALSE, 10);

  my $label = Gtk2::Label->new($message);
  $label->set_line_wrap(TRUE);
  $label->set_selectable(TRUE);
  $box->pack_start($label, FALSE, TRUE, 10);

  $dialog->vbox->pack_start($box, FALSE, FALSE, 10);
  $dialog->vbox->show_all;

  $self->add_detail($dialog, $detail) if($detail);

  $dialog->add_button('_Dismiss' => 'ok');

  $dialog->action_area->show_all;

  return $dialog;
}


sub add_detail {
  my($self, $dialog, $detail) = @_;

  my $sw = Gtk2::ScrolledWindow->new;
  $sw->set_policy ('automatic', 'automatic');
  $sw->set_shadow_type ('in');

  my $text_view   = Gtk2::TextView->new;
  my $text_buffer = Gtk2::TextBuffer->new;
  $text_buffer->set_text($detail);

  $text_view->set_wrap_mode ('word');
  $text_view->set_buffer($text_buffer);
  $text_view->set_editable(FALSE);
  $text_view->set_cursor_visible(FALSE);
  $sw->add($text_view);

  $dialog->vbox->pack_start($sw, TRUE, TRUE, 10);

  my $detail_button = Gtk2::Button->new("Show De_tails");
  $detail_button->signal_connect(
    "clicked" => sub {
      if($sw->visible) {
        $sw->hide;
        $detail_button->set_label("Show De_tails");
      }
      else {
        $sw->show_all;
        $detail_button->set_label("Hide De_tails");
      }
    }
  );
  $dialog->add_action_widget($detail_button, 'none');
  
}

1;

