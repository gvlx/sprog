package Sprog::GtkView;

use strict;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app_win
  toolbar
  canvas
  statusbar
  app
));

use Scalar::Util qw(weaken);
use File::Basename ();

use Gtk2 '-init';
use Glib qw(TRUE FALSE);
use Gnome2::Canvas;
use Gtk2::SimpleMenu;

use Sprog::GtkView::Chrome;
use Sprog::GtkView::Toolbar;
use Sprog::GtkView::AlertDialog;
use Sprog::GtkGearView;


sub new {
  my $class = shift;

  my $self = bless {
    @_,
    gears => {},
  }, $class;
  $self->{app} && weaken($self->{app});

  $self->build_app_window;

  return $self;
}


sub run {
  my $self = shift;

  Gtk2->main;
}


sub build_app_window {
  my $self = shift;

  my $app_win = $self->app_win(Gtk2::Window->new);
  $app_win->signal_connect(destroy => sub { Gtk2->main_quit; });
  $app_win->set_default_size (450, 420);

  my $vbox = Gtk2::VBox->new(FALSE, 0);
  $app_win->add($vbox);

  $self->add_menubar($vbox);
  $self->add_toolbar($vbox);
  $self->add_workbench($vbox);
  $self->add_statusbar($vbox);
  $self->set_window_title;

  $app_win->show_all;
}


sub add_menubar {
  my($self, $vbox) = @_;

  my $action = 0;
  my $app = $self->app;
  my $menu_tree = [
    _File  => {
      item_type  => '<Branch>',
      children => [
        _New => {
          callback        => sub { $app->file_new },
          callback_action => $action++,
        },
        _Open => {
          callback        => sub { $app->file_open },
          callback_action => $action++,
          accelerator     => '<ctrl>O',
        },
        _Save => {
          callback        => sub { $app->file_save },
          callback_action => $action++,
          accelerator     => '<ctrl>S',
        },
        'Save _As' => {
          callback        => sub { $app->file_save_as },
          callback_action => $action++,
        },
        _Quit => {
          callback        => sub { Gtk2->main_quit; },
          callback_action => $action++,
          accelerator     => '<ctrl>Q',
        },
      ],
    },
    _Machine  => {
      item_type  => '<Branch>',
      children => [
        _Run => {
          callback        => sub { $app->run_machine; },
          callback_action => $action++,
          accelerator     => '<ctrl>R',
        },
        _Stop => {
          callback        => sub { $app->stop_machine; },
          callback_action => $action++,
        },
      ],
    },
    _Test  => {
      item_type  => '<Branch>',
      children => [
        'Add a _Top gear'  => {
          item_type  => '<Branch>',
          children => [
            'Read _File' => {
              callback        => sub { $self->test_new('Sprog::Gear::ReadFile') },
              callback_action => $action++,
              accelerator     => '<ctrl>F',
            },
            'Run a _Command' => {
              callback        => sub { $self->test_new('Sprog::Gear::CommandIn') },
              callback_action => $action++,
              accelerator     => '<ctrl>C',
            },
          ]
        },
        'Add a _Filter gear'  => {
          item_type  => '<Branch>',
          children => [
            'Pattern Match' => {
              callback        => sub { $self->test_new('Sprog::Gear::Grep') },
              callback_action => $action++,
              accelerator     => '<ctrl>G',
            },
            'F_ind\/Replace' => {
              callback        => sub { $self->test_new('Sprog::Gear::FindReplace') },
              callback_action => $action++,
              accelerator     => '<ctrl>I',
            },
            '_Perl Code' => {
              callback        => sub { $self->test_new('Sprog::Gear::PerlCode') },
              callback_action => $action++,
              accelerator     => '<ctrl>P',
            },
            '_Lowercase' => {
              callback        => sub { $self->test_new('Sprog::Gear::LowerCase') },
              callback_action => $action++,
              accelerator     => '<ctrl>L',
            },
            '_Uppercase' => {
              callback        => sub { $self->test_new('Sprog::Gear::UpperCase') },
              callback_action => $action++,
              accelerator     => '<ctrl>U',
            },
          ]
        },
        'Add a _Bottom gear'  => {
          item_type  => '<Branch>',
          children => [
            '_Text Window' => {
              callback        => sub { $self->test_new('Sprog::Gear::TextWindow') },
              callback_action => $action++,
              accelerator     => '<ctrl>T',
            },
          ]
        },
        'Futures (AKA vapourware)'  => {
          item_type  => '<Branch>',
          children => [
            'CSV Split' => {
              callback        => sub { $self->test_new('Sprog::Gear::CSVSplit') },
              callback_action => $action++,
            },
            'Parse Apache Log' => {
              callback        => sub { $self->test_new('Sprog::Gear::ApacheLogParse') },
              callback_action => $action++,
              accelerator     => '<ctrl>A',
            },
            'Perl Code (hash to pipe)' => {
              callback        => sub { $self->test_new('Sprog::Gear::PerlCodeHP') },
              callback_action => $action++,
              accelerator     => '<ctrl>H',
            },
            'Parse XML' => {
              callback        => sub { $self->test_new('Sprog::Gear::XMLToSAX') },
              callback_action => $action++,
            },
            'XSLT Transform' => {
              callback        => sub { $self->test_new('Sprog::Gear::XSLT') },
              callback_action => $action++,
            },
            'Write XML' => {
              callback        => sub { $self->test_new('Sprog::Gear::XMLWriter') },
              callback_action => $action++,
            },
          ]
        },
#        '_Dump machine state' => {
#          callback        => sub { $self->dump },
#          callback_action => $action++,
#          accelerator     => '<ctrl>D',
#        },
      ],
    },
  ];

  my $menu = Gtk2::SimpleMenu->new(menu_tree => $menu_tree);

  $vbox->pack_start($menu->{widget}, FALSE, TRUE, 0);
  $self->app_win->add_accel_group($menu->{accel_group});
}


sub add_toolbar {
  my($self, $vbox) = @_;

  my $toolbar = Sprog::GtkView::Toolbar->new(app => $self->app);
  $self->toolbar($toolbar);
  $vbox->pack_start($toolbar->widget, FALSE, TRUE, 0);
}


sub  enable_tool_button { $_[0]->toolbar->set_sensitive($_[1], TRUE);  }
sub disable_tool_button { $_[0]->toolbar->set_sensitive($_[1], FALSE); }


sub add_workbench {
  my($self, $vbox) = @_;

  my $scroller = Gtk2::ScrolledWindow->new;
  my $canvas   = Gnome2::Canvas->new_aa;
  $scroller->add ($canvas);
  $self->canvas($canvas);

  my $color = Gtk2::Gdk::Color->parse ("#007f00");
  $canvas->modify_bg ('normal', $color);

  $scroller->set_policy ('automatic', 'automatic');
  $vbox->pack_start($scroller, TRUE, TRUE, 0);
  $canvas->set_scroll_region (0, 0, 400, 300);

}


sub add_statusbar {
  my($self, $vbox) = @_;

  my $statusbar = $self->statusbar(Gtk2::Statusbar->new);
  $vbox->pack_start($statusbar, FALSE, TRUE, 0);
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
  my $dialog = Gtk2::MessageDialog->new (
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


sub test_new {
  my($self, $gear_class) = @_;

  my $machine = $self->app->machine;
  my $gear = $machine->add_gear($gear_class) or return; # on error
  $self->add_gear_view($gear);
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

  return Glib::IO->add_watch (fileno($fh), ['in', 'err', 'hup'], $sub);
}

sub dump {
  my($self) = @_;

  foreach my $id (sort {$a <=> $b} keys %{$self->{gears}}) {
    $self->{gears}->{$id}->dump;
  }
}

1;
