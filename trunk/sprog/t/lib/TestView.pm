package TestView;

use base qw(Sprog::GtkView);

use strict;
use warnings;


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
    if($widget->isa('Gtk2::Button') 
       and  $widget->get_label
       and  $widget->get_label =~ /$name/i
      );

  if($widget->can('get_children')) {
    foreach ($widget->get_children) {
      my $button = $self->find_button($_, $name);
      return $button if($button);
    }
  }

  return;
}


sub get_tool_buttons {
  my($self) = @_;

  my(@buttons, %map);

  $self->walk_children(
    $self->toolbar->widget,
    sub { $_ = shift; push @buttons, $_ if $_->isa('Gtk2::Button'); }
  );

  foreach my $b (@buttons) {
    my $k = '';
    $self->walk_children($b, 
      sub { $k = $_[0]->get_label if $_[0]->isa('Gtk2::Label'); } 
    );
    $map{$k} = $b;
  }

  return %map;
}


sub walk_children {
  my($self, $widget, $callback) = @_;

  $callback->($widget);

  if($widget->can('get_children')) {
    $self->walk_children($_, $callback) foreach ($widget->get_children);
  }
}


1;

