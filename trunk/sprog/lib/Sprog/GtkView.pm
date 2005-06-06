package Sprog::GtkView;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app_win
  chrome_class
  alert_class
  help_class
  about_class
  menubar
  toolbar
  workbench
  statusbar
  palette_pane
  palette_win
  palette
  floating_palette
  app
  width
  height
));

use Scalar::Util qw(weaken);
use File::Basename ();

use Glib qw(TRUE FALSE);

use constant TARG_STRING  => 0;
use constant DEFAULT_WIN_WIDTH  => 750;
use constant DEFAULT_WIN_HEIGHT => 560;

sub new {
  my $class = shift;

  my $self = bless { 
    @_, 
    palette_visible => 0,
  }, $class;
  weaken($self->{app});

  $self->{floating_palette} = 0;

  my $app = $self->app;
  $app->inject(
    '/app/view/chrome'       => 'Sprog::GtkView::Chrome',
    '/app/view/menubar'      => 'Sprog::GtkView::Menubar',
    '/app/view/toolbar'      => 'Sprog::GtkView::Toolbar',
    '/app/view/workbench'    => 'Sprog::GtkView::WorkBench',
    '/app/view/alert_dialog' => 'Sprog::GtkView::AlertDialog',
    '/app/view/about_dialog' => 'Sprog::GtkView::AboutDialog',
    '/app/view/palette'      => 'Sprog::GtkView::Palette',
    '/app/view/help_viewer'  => 'Sprog::GtkView::HelpViewer',
  );

  $self->chrome_class($app->load_class('/app/view/chrome'));
  $self->alert_class ($app->load_class('/app/view/alert_dialog'));
  $self->about_class ($app->load_class('/app/view/about_dialog'));
  $self->help_class  ($app->load_class('/app/view/help_viewer'));

  $self->build_app_window;

  return $self;
}


sub build_app_window {
  my $self = shift;

  my $app_win = $self->app_win(Gtk2::Window->new);
  $app_win->signal_connect(destroy => sub { $self->app->quit; });
  $self->width ($self->app->get_pref('app_win.width')  || DEFAULT_WIN_WIDTH);
  $self->height($self->app->get_pref('app_win.height') || DEFAULT_WIN_HEIGHT);
  $app_win->set_default_size($self->width, $self->height);

  my $vbox = Gtk2::VBox->new(FALSE, 0);
  $app_win->add($vbox);

  my $hpaned = $self->palette_pane(Gtk2::HPaned->new);
  $hpaned->pack2($self->_build_workbench, TRUE, FALSE);

  $vbox->pack_start($self->_build_menubar,   FALSE, TRUE, 0);
  $vbox->pack_start($self->_build_toolbar,   FALSE, TRUE, 0);
  $vbox->pack_start($hpaned,                 TRUE,  TRUE, 0);
  $vbox->pack_start($self->_build_statusbar, FALSE, TRUE, 0);

  $self->set_window_title;

  $app_win->show_all;

  $self->_add_palette;

  $app_win->signal_connect(
    size_allocate => sub { $self->on_size_allocate(@_); }
  );
}


sub apply_prefs {
  my $self = shift;
  
  my $app = $self->app;

  $self->show_palette if $app->get_pref('palette.visible');

  $self->menubar->set_toolbar_style($app->get_pref('toolbar.style'));

  my $toolbar = $app->get_pref('toolbar.visible');
  $toolbar = 1 if !defined($toolbar);
  $self->hide_toolbar unless $toolbar;
}


sub on_size_allocate {
  my($self, $window, $rect) = @_;

  my($width, $height) = ($rect->width, $rect->height);

  if($self->width != $width) {
    $self->width($width);
    $self->app->set_pref('app_win.width', $width);
  }
  if($self->height != $height) {
    $self->height($height);
    $self->app->set_pref('app_win.height', $height);
  }
}


sub _build_menubar {
  my($self) = @_;

  my $menubar = $self->app->make_class('/app/view/menubar', app => $self->app);
  $self->menubar($menubar);

  $self->app_win->add_accel_group($menubar->accel_group);

  return $menubar->widget;
}


sub _build_toolbar {
  my($self) = @_;

  return $self->toolbar(
    $self->app->make_class('/app/view/toolbar', app => $self->app)
  )->widget;
}

sub show_toolbar        { $_[0]->toolbar->show;                        }
sub hide_toolbar        { $_[0]->toolbar->hide;                        }

sub set_toolbar_style   { $_[0]->toolbar->set_style($_[1]);            }
sub  enable_tool_button { $_[0]->toolbar->set_sensitive($_[1], TRUE);  }
sub disable_tool_button { $_[0]->toolbar->set_sensitive($_[1], FALSE); }

sub  enable_menu_item   { $_[0]->menubar->set_sensitive($_[1], TRUE);  }
sub disable_menu_item   { $_[0]->menubar->set_sensitive($_[1], FALSE); }

sub update_gear_view    { shift->workbench->update_gear_view(@_);      }


sub _build_workbench {
  my($self) = @_;

  return $self->workbench(
    $self->app->make_class(
      '/app/view/workbench', app => $self->app, view => $self
    )
  )->widget;
}

sub gear_view_by_id        { shift->workbench->gear_view_by_id(@_);        }
sub delete_gear_view_by_id { shift->workbench->delete_gear_view_by_id(@_); }
sub add_gear_view          { shift->workbench->add_gear_view(@_);          }
sub drop_gear              { shift->workbench->drop_gear(@_);              }


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


sub drag_targets {
  return {'target' => "STRING", 'flags' => ['same-app'], 'info' => TARG_STRING};
};


sub running {
  my $self = shift;

  if(@_) {
    if($_[0]) {
      $self->enable_tool_button('stop');
      $self->disable_tool_button('run');
      $self->enable_menu_item('/Machine/Stop');
      $self->disable_menu_item('/Machine/Run');
      $self->app->add_timeout(200, sub { $self->turn_cogs });
    }
    else {
      $self->disable_tool_button('stop');
      $self->enable_tool_button('run');
      $self->disable_menu_item('/Machine/Stop');
      $self->enable_menu_item('/Machine/Run');
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
  return $self->workbench->turn_cogs;
}


sub alert {
  my($self, $message, $detail) = @_;

  $self->alert_class->invoke($self->app_win, $message, $detail);

  return;
}


sub confirm_yes_no {
  my($self, $message) = @_;

  my $dialog = Gtk2::MessageDialog->new(
    $self->app_win,
    [qw/modal destroy-with-parent/],
    'question',
    'yes-no',
    $message
  );
  my $response = $dialog->run;
  $dialog->destroy;

  return $response eq 'yes';
}


sub _add_palette {
  my($self) = @_;

  my $palette = $self->app->make_class(
    '/app/view/palette', app => $self->app, view => $self
  );
  $self->palette($palette);

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


sub palette_visible {
  my $self = shift;
  
  if(@_  and  $self->{palette_visible} ne $_[0]) {
    $self->{palette_visible} = shift;
    $self->app->set_pref('palette.visible', $self->{palette_visible});
  }
  return $self->{palette_visible};
}


sub show_help {
  my($self, $topic) = @_;

  $self->help_class->show_help($self->app, $topic);
}


sub help_about {
  my($self, $data) = @_;

  $self->about_class->invoke($self->app_win, $data, $self->chrome_class);
}


sub status_message {
  my($self, $message) = @_;

  my $statusbar = $self->statusbar;
  $statusbar->pop(0);
  $statusbar->push(0, $message);
}

1;

