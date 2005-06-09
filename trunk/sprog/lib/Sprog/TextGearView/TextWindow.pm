package Sprog::TextGearView::TextWindow;

use base qw(Sprog::TextGearView);

sub clear { return; }

sub add_data {
  my($self, $data) = @_;

  print $data;
}


1;
