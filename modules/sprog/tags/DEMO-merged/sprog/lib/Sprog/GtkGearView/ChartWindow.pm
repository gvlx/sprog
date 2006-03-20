package Sprog::GtkGearView::ChartWindow;

use strict;

use base qw(Sprog::GtkGearView);

__PACKAGE__->mk_accessors(qw(
  gear_win
  text_view
  text_buffer
));

use Glib qw(TRUE FALSE);

use GD::Graph::bars;


use constant CHART_MARGIN => 16;


sub reset {
  my $self = shift;

  my $win = $self->gear_win or return;
  $win->destroy;
  $self->gear_win(undef);
}


sub show_chart {
  my($self, $data) = @_;

  if(!$self->gear_win) {
    $self->create_window or return;
  }
  $self->gear_win->show;
}


sub create_window {
  my $self = shift;

  my $app_win = $self->app->view->app_win;

  my $dialog = Gtk2::Dialog->new(
    "Sprog Chart",
    $app_win,
    [qw/destroy-with-parent no-separator/],
  );
  $dialog->signal_connect('delete_event' => sub { $dialog->hide; return 1 });

  my $image = eval { $self->chart_image };
  return $self->app->alert("Error creating chart", "$@") if($@);
  return unless $image;

  my $box = Gtk2::EventBox->new;
#  $box->set_border_width(12);
  $box->modify_bg('normal', Gtk2::Gdk::Color->parse('#FFFFFF'));
  $box->add($image);

  my $frame = Gtk2::Frame->new;
  $frame->set_shadow_type('in');
  $frame->add($box);

  $dialog->vbox->add($frame);

  my $hide_button = Gtk2::Button->new("_Hide");
  $hide_button->signal_connect( "clicked" => sub { $dialog->hide; } );
  $dialog->add_action_widget($hide_button, 'none');

  $dialog->signal_connect(
    "key_press_event" => sub { $self->on_key_press(@_); } 
  );

  $self->gear_win($dialog);
  $dialog->show_all;
}


sub chart_image {
  my $self = shift;

  my($width, $height) = (400, 300);
  my $chart = GD::Graph::bars->new($width, $height) or die GD::Graph->error . "\n";
  $chart->set(
    transparent   => 0,
    bar_spacing   => 1,
    accentclr     => 'black',
    bgclr         => 'white',
    boxclr        => 'white',
    dclrs         => ['#0066CC'],
    x_tick_length => -2,
    y_long_ticks  => 1,
    t_margin      => CHART_MARGIN,
    b_margin      => CHART_MARGIN,
    l_margin      => CHART_MARGIN,
    r_margin      => CHART_MARGIN,
  ) or die $chart->error . "\n";

  my $data = $self->gear->data_series or die "No data series for chart\n";

  $chart->plot($data) or die $chart->error . "\n";

  my $png = $chart->gd->png or die $chart->error . "\n";
  my $loader = Gtk2::Gdk::PixbufLoader->new;
  $loader->write($png);
  $loader->close;

  return Gtk2::Image->new_from_pixbuf($loader->get_pixbuf);
}


sub on_key_press {
  my($self, $dialog, $event) = @_;

  return FALSE unless($event->keyval == $Gtk2::Gdk::Keysyms{Escape});

  $dialog->hide;
  return TRUE;
}


1;

