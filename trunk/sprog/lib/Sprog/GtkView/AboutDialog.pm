package Sprog::GtkView::AboutDialog;

use strict;

use Glib qw(TRUE FALSE);


sub new {
  my $class = shift;
  return bless { @_ }, $class;
}


sub invoke {
  my($class, $parent, $data, $chrome) = @_;

  my $self = $class->new;

  my $dialog = $self->build_dialog($parent, $data, $chrome);

  my $return;
  while(!$return or $return eq 'none') {
    $return = $dialog->run;
  }

  $dialog->destroy;
}


sub build_dialog {
  my($self, $parent, $data, $chrome) = @_;

  my $dialog = Gtk2::Dialog->new_with_buttons(
    "About",
    $parent,
    [qw/modal destroy-with-parent no-separator/],
    'Close' => 'close',
  );
  $dialog->set_default_size (350, 220);

  my $logo = Gtk2::Image->new_from_pixbuf($chrome->about_logo);
  $dialog->vbox->pack_start($logo, FALSE, FALSE, 4);

  my $detail = Gtk2::Label->new;
  $detail->set_selectable(TRUE);
  $detail->set_markup(
    qq(<span font_desc="Sans Bold 24">$data->{app_detail}</span>)
  );
  $dialog->vbox->pack_start($detail, FALSE, FALSE, 4);

  my $copyright = Gtk2::Label->new(" $data->{copyright} ");;
  $copyright->set_selectable(TRUE);
  $dialog->vbox->pack_start($copyright, FALSE, FALSE, 4);

  my $url = Gtk2::Label->new($data->{project_url});;
  $url->set_selectable(TRUE);
  $dialog->vbox->pack_start($url, FALSE, FALSE, 4);

  $dialog->action_area->set_layout('spread');  # Center the button

  $dialog->show_all;

  return $dialog;
}

1;

