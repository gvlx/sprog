package TestView;

use base qw(Sprog::GtkView);


sub activate_menu_item {
  my($self, $path) = @_;

  my $item = $self->menubar->menu->get_item($path) or return;

  $item->activate;

  return 1;
}


1;

