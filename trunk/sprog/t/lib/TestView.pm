package TestView;

use base qw(Sprog::GtkView);


sub activate_menu_item {
  my($self, $path) = @_;

  my $item = $self->menubar->menu->get_item($path) or return;

  $item->activate;

  return 1;
}


sub find_window {
  my($self, $name) = @_;

  foreach my $window (Gtk2::Window->list_toplevels) {
    my $title = $window->get_title or next;
    return $window if($title =~ /$name/i);
  }

  return;
}


sub find_button {
  my($self, $widget, $name) = @_;

  return $widget
    if($widget->isa('Gtk2::Button')  and  $widget->get_label =~ /$name/i);

  if($widget->can('get_children')) {
    foreach ($widget->get_children) {
      my $button = $self->find_button($_, $name);
      return $button if($button);
    }
  }

  return;
}


1;

