package Sprog::GtkView;

use strict;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app_win
  menubar
  toolbar
  canvas
  statusbar
  palette_pane
  palette_win
  palette
  palette_visible
  floating_palette
  app
));

use Scalar::Util qw(weaken);
use File::Basename ();

use Gtk2 '-init';
use Glib qw(TRUE FALSE);
use Gnome2::Canvas;
use Gtk2::SimpleMenu;

use Sprog::GtkView::Chrome;
use Sprog::GtkView::Menubar;
use Sprog::GtkView::Toolbar;
use Sprog::GtkView::AlertDialog;
use Sprog::GtkView::AboutDialog;
use Sprog::GtkView::Palette;
use Sprog::GtkGearView;

use constant TARG_STRING  => 0;

sub new {
  my $class = shift;

  my $self = bless {
    @_,
    gears => {},
  }, $class;
  $self->{app} && weaken($self->{app});

  $self->{floating_palette} = 0;

  $self->build_app_window;

  return $self;
}


sub run  { Gtk2->main;      }
sub quit { Gtk2->main_quit; }


sub build_app_window {
  my $self = shift;

  my $app_win = $self->app_win(Gtk2::Window->new);
  $app_win->signal_connect(destroy => sub { $self->app->quit; });
  $app_win->set_default_size(750, 560);

  my $vbox = Gtk2::VBox->new(FALSE, 0);
  $app_win->add($vbox);

  $vbox->pack_start($self->_build_menubar,   FALSE, TRUE, 0);
  $vbox->pack_start($self->_build_toolbar,   FALSE, TRUE, 0);
  $vbox->pack_start($self->_build_workbench, TRUE,  TRUE, 0);
  $vbox->pack_start($self->_build_statusbar, FALSE, TRUE, 0);

  $self->set_window_title;

  $app_win->show_all;

  $self->_add_palette;
}


sub _build_menubar {
  my($self) = @_;

  my $menubar = Sprog::GtkView::Menubar->new(app => $self->app);
  $self->menubar($menubar);

  $self->app_win->add_accel_group($menubar->accel_group);

  return $menubar->widget;
}


sub _build_toolbar {
  my($self) = @_;

  my $toolbar = Sprog::GtkView::Toolbar->new(app => $self->app);
  $self->toolbar($toolbar);

  return $toolbar->widget;
}

sub show_toolbar        { $_[0]->toolbar->widget->show                 }
sub hide_toolbar        { $_[0]->toolbar->widget->hide                 }

sub set_toolbar_style   { $_[0]->toolbar->set_style($_[1]);            }
sub  enable_tool_button { $_[0]->toolbar->set_sensitive($_[1], TRUE);  }
sub disable_tool_button { $_[0]->toolbar->set_sensitive($_[1], FALSE); }


sub _build_workbench {
  my($self) = @_;

  my $sw = Gtk2::ScrolledWindow->new;
  $sw->set_policy('automatic', 'automatic');

  my $canvas = Gnome2::Canvas->new_aa;
  $self->canvas($canvas);
#  $canvas->signal_connect(size_allocate => sub { $self->_reset_canvas_scroll_region; });

  $sw->add($canvas);

  my $color = Gtk2::Gdk::Color->parse("#007f00");
  $canvas->modify_bg('normal', $color);

  $canvas->set_scroll_region(0, 0, 400, 300);

  # Set up as target for drag-n-drop

  $canvas->drag_dest_set('all', ['copy'], $self->drag_targets);
  $canvas->signal_connect(
    drag_data_received => sub { $self->drag_data_received(@_); }
  );

  #return $sw;

  my $hpaned = Gtk2::HPaned->new;
  $hpaned->pack2($sw, TRUE, FALSE);

  $self->palette_pane($hpaned);

  return $hpaned;
}


sub _build_statusbar {
  my($self) = @_;

  return $self->statusbar(Gtk2::Statusbar->new);
}


sub set_window_title {
  my $self = shift;

  my $title = 'Untitled';

  my $filename = $self->app->filename;
  if(defined($filename)) {
    my($name, $path) = File::Basename::basename($filename);
    $title = $name;
  }
  $self->app_win->set_title("$title - Sprog");
}


sub _reset_canvas_scroll_region {
  my($self) = @_;


  my($x1, $y1, $x2, $y2);
  while(my($id, $gv) = each %{$self->{gears}}) {
    if(!defined($x1)) {
      ($x1, $y1, $x2, $y2) = $gv->group->get_bounds;
      next;
    }
    my($ix1, $iy1, $ix2, $iy2) = $gv->group->get_bounds;

    $x1 = $ix1 - 10 if($ix1 < $x1);
    $y1 = $iy1 - 10 if($iy1 < $y1);
    $x2 = $ix2 + 10 if($ix2 > $x2);
    $y2 = $iy2 + 10 if($iy2 > $y2);
  }
  return unless defined $x1;
  $self->canvas->set_scroll_region($x1, $y1, $x2, $y2);
}


sub drag_targets {
  return {'target' => "STRING", 'flags' => ['same-app'], 'info' => TARG_STRING};
};


sub drag_data_received {
  my($self, $canvas, $context, $x, $y, $data, $info, $time) = @_;

  if(($data->length < 1) || ($data->format != 8)) {
    $context->finish (0, 0, $time);
    return
  }

  my $gear_class = $data->data;
  $context->finish (1, 0, $time);

  my $gear = $self->app->add_gear_at_x_y($gear_class, $x, $y) or return;
  my $gearview = $self->gear_view_by_id($gear->id);

  my($cx, $cy) = $canvas->window_to_world($x, $y);
  $self->app->drop_gear($gearview, $cx, $cy);

  return;
}


sub running {
  my $self = shift;

  if(@_) {
    if($_[0]) {
      $self->enable_tool_button('stop');
      $self->disable_tool_button('run');
      Glib::Timeout->add(200, sub { $self->turn_cogs });
    }
    else {
      $self->disable_tool_button('stop');
      $self->enable_tool_button('run');
    }
    $self->{running} = shift;
  }

  return $self->{running};
}


sub file_open_filename {
  my $self = shift;

  my $file_chooser = Gtk2::FileChooserDialog->new(
    'Open',
    undef,
    'open',
    'gtk-cancel' => 'cancel',
    'gtk-ok'     => 'ok'
  );
  $self->_add_sprog_file_filter($file_chooser);

  my $filename = undef;
  if($file_chooser->run eq 'ok') {
    $filename = $file_chooser->get_filename;
  }
  $file_chooser->destroy;

  return $filename;
}


sub file_save_as_filename {
  my $self = shift;
  
  my $file_chooser = Gtk2::FileChooserDialog->new(
    'Save as',
    undef,
    'save',
    'gtk-cancel' => 'cancel',
    'gtk-ok'     => 'ok'
  );
  $self->_add_sprog_file_filter($file_chooser);
  my $default = $self->app->filename;
  $file_chooser->set_filename($default) if $default;

  my $filename = undef;
  while($file_chooser->run ne 'cancel') {
    $filename = $file_chooser->get_filename;
    $filename .= '.sprog' if $filename !~ /\.sprog$/;
    last if ! -f $filename || $self->confirm("File exists.  Overwrite?");
    $filename = undef;
  };
  $file_chooser->destroy;

  return $filename;
}


sub confirm {
  my($self, $message, $parent) = @_;

  $parent ||= $self->app_win;
  my $dialog = Gtk2::MessageDialog->new(
    $parent, 
    'destroy-with-parent',
    'question', 
    'yes-no',
    $message,
  );

  my $result = $dialog->run;
  $dialog->destroy;

  return $result eq 'yes' ? TRUE : FALSE;
}


sub _add_sprog_file_filter {
  my($self, $file_chooser) = @_;

  my $filter = Gtk2::FileFilter->new;
  $filter->add_mime_type('application/x-sprog');
  $filter->add_pattern("*.sprog");
  $filter->set_name("Sprog machine files (*.sprog)");
  $file_chooser->add_filter($filter);
}

sub turn_cogs {
  my $self = shift;

  return FALSE unless $self->{running};

  foreach my $gear_view (values %{$self->{gears}}) {
    my $gear = $gear_view->gear;
    if($gear->work_done) {
      $gear_view->turn_cog;
      $gear->work_done(0);
    }
  }
  return TRUE;
}


sub alert {
  my($self, $message, $detail) = @_;

  Sprog::GtkView::AlertDialog->invoke($self->app_win, $message, $detail);

  return;
}


sub _add_palette {
  my($self) = @_;

  my $palette = $self->palette(Sprog::GtkView::Palette->new(app => $self->app));

  return $self->_add_floating_palette($palette) if($self->floating_palette);

  my $widget = $palette->widget;
  $self->palette_pane->pack1($widget, FALSE, FALSE);
  $self->palette_win($widget);
  $widget->hide;
}


sub _add_floating_palette {
  my($self, $palette) = @_;

  my $win = Gtk2::Window->new;
  $self->palette_win($win);

  $win->set_title ("Sprog Gear Palette");
  $win->set_default_size (200, 420);

  $win->signal_connect(delete_event => sub { $self->app->hide_palette; TRUE } );

  $win->add($palette->widget);
}


sub toggle_palette {
  my($self) = @_;

  if($self->palette_visible) {
    $self->hide_palette;
  }
  else {
    $self->show_palette;
  }
}


sub show_palette {
  my($self) = @_;

  $self->menubar->set_palette_active(TRUE);
  $self->toolbar->set_palette_active(TRUE);
  $self->palette_win->show;
  $self->palette->search_entry->grab_focus;
  $self->palette->search_button->grab_default;
  $self->palette_visible(1);
}


sub hide_palette {
  my($self) = @_;

  $self->menubar->set_palette_active(FALSE);
  $self->toolbar->set_palette_active(FALSE);
  $self->palette_win->hide();
  $self->palette_visible(0);
}


sub help_about {
  my($self, $data) = @_;

  Sprog::GtkView::AboutDialog->invoke($self->app_win, $data);
}


sub add_gear_view {
  my($self, $gear) = @_;

  my $gear_view = Sprog::GtkGearView->add_gear($self->app, $self->canvas, $gear);
  $self->gear_view_by_id($gear->id, $gear_view);
}


sub gear_view_by_id {
  my $self = shift;
  my $id   = shift;
  $self->{gears}->{$id} = shift if(@_);
  return $self->{gears}->{$id};
}


sub delete_gear_view_by_id {
  my($self, $id) = @_;

  my $gear_view = delete $self->{gears}->{$id} || return;
  $gear_view->delete_view;
}


sub drop_gear {
  my($self, $gearv, $x, $y) = @_;

  my $gear = $gearv->gear;
  my $input_type = $gear->input_type              || return;

  my $target = $self->canvas->get_item_at($x, $y) || return;
  $target = $target->parent                       || return;
  my $tg_id = $target->get_property('user_data')  || return;
  my $tgv = $self->gear_view_by_id($tg_id)        || return;
  $tg_id = $tgv->gear->last->id;
  $tgv = $self->gear_view_by_id($tg_id)           || return;
  my $tg = $tgv->gear;
  my $output_type = $tg->output_type              || return;
  return unless $input_type eq $output_type;

  $tg->next($gear);

  $gearv->move(
    $tg->x - $gear->x, 
    $tg->y + $tgv->gear_height - $gear->y
  );
}


sub add_idle_handler {
  my($self, $sub) = @_;

  return Glib::Idle->add($sub);
}


sub add_io_reader {
  my($self, $fh, $sub) = @_;

  return Glib::IO->add_watch(fileno($fh), ['in', 'err', 'hup'], $sub);
}


sub status_message {
  my($self, $message) = @_;

  my $statusbar = $self->statusbar;
  $statusbar->pop(0);
  $statusbar->push(0, $message);
}


sub dump {
  my($self) = @_;

  foreach my $id(sort {$a <=> $b} keys %{$self->{gears}}) {
    $self->{gears}->{$id}->dump;
  }
}

1;
