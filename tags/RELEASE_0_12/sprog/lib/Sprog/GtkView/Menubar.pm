package Sprog::GtkView::Menubar;

use strict;

use base qw(Sprog::Accessor);

__PACKAGE__->mk_accessors(qw(
  app
  menu
));

use Scalar::Util qw(weaken);

use Gtk2;
use Glib qw(TRUE FALSE);
use Gtk2::SimpleMenu;

use constant TOOLBAR_STYLE => 1;

sub new {
  my $class = shift;

  my $self = bless { @_, }, $class;
  weaken($self->{app});

  $self->_build_menubar;

  return $self;
}


sub _build_menubar {
  my $self = shift;

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
          callback        => sub { $app->quit; },
          callback_action => $action++,
          accelerator     => '<ctrl>Q',
        },
      ],
    },
    _View  => {
      item_type  => '<Branch>',
      children => [
        _Palette => {
          item_type       => '<CheckItem>',
          callback        => sub { $app->toggle_palette; },
          callback_action => $action++,
          accelerator     => 'F9',
        },
        _Toolbar => {
          item_type       => '<CheckItem>',
          callback        => sub { $self->_toggle_toolbar(@_); },
          callback_action => $action++,
        },
        'Toolbar _Style' => {
            item_type  => '<Branch>',
            children => [
                'Icons _and Text' => {
                  item_type       => '<RadioItem>',
                  callback        => sub { $app->set_toolbar_style('both'); },
                  callback_action => $action++,
                  groupid         => TOOLBAR_STYLE,
                },
                '_Icons Only' => {
                  item_type       => '<RadioItem>',
                  callback        => sub { $app->set_toolbar_style('icons'); },
                  callback_action => $action++,
                  groupid         => TOOLBAR_STYLE,
                },
                '_Text Only' => {
                  item_type       => '<RadioItem>',
                  callback        => sub { $app->set_toolbar_style('text'); },
                  callback_action => $action++,
                  groupid         => TOOLBAR_STYLE,
                },
                'Text Be_side Icons' => {
                  item_type       => '<RadioItem>',
                  callback        => sub { $app->set_toolbar_style('both-horiz'); },
                  callback_action => $action++,
                  groupid         => TOOLBAR_STYLE,
                },
            ]
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
        'Run when files _dropped' => {
          item_type       => '<CheckItem>',
          callback        => sub { $self->_toggle_run_on_drop(@_); },
          callback_action => $action++,
        },
      ],
    },
    _Tools  => {
      item_type  => '<Branch>',
      children => [
        _Preferences => {
          callback        => sub { $app->prefs_dialog },
          callback_action => $action++,
        },
      ],
    },
    _Help  => {
      item_type  => '<Branch>',
      children => [
        _Contents => {
          callback        => sub { $app->help_contents },
          callback_action => $action++,
          accelerator     => 'F1',
        },
        _About => {
          callback        => sub { $app->help_about },
          callback_action => $action++,
        },
      ],
    },
  ];

  my $menu = Gtk2::SimpleMenu->new(menu_tree => $menu_tree);
  $self->menu($menu);


  my $flag = $self->app->get_pref('toolbar.visible');
  $flag = (defined($flag) and !$flag) ? FALSE : TRUE;
  $menu->get_widget('/View/Toolbar')->set_active($flag);
  
  $menu->get_widget('/Machine/Stop')->set_sensitive(FALSE);

  return $menu;
}


sub accel_group { shift->menu->{accel_group} };
sub widget      { shift->menu->{widget}      };


sub set_palette_active {
  my($self, $state) = @_;

  my $item = $self->menu->get_widget('/View/Palette') or return;
  $item->set_active($state);
}


sub set_toolbar_style {
  my $self  = shift;

  my $style = $self->app->get_pref('toolbar.style') || 'both';

  my %map = (
    'both'       => '/View/Toolbar Style/Icons and Text',
    'icons'      => '/View/Toolbar Style/Icons Only',
    'text'       => '/View/Toolbar Style/Text Only',
    'both-horiz' => '/View/Toolbar Style/Text Beside Icons',
  );

  my $path = $map{$style} or return;

  my $item = $self->menu->get_widget($path) or return;
  $item->set_active(TRUE);
}


sub set_sensitive {
  my($self, $path, $state) = @_;

  my $item = $self->menu->get_widget($path) or return;
  $item->set_sensitive($state);
}


sub _toggle_toolbar {
  my($self, $data, $action, $item) = @_;

  if($item->get_active) {
    $self->app->show_toolbar;
  }
  else {
    $self->app->hide_toolbar;
  }
}


sub _toggle_run_on_drop {
  my($self, $data, $action, $item) = @_;

  $self->app->set_run_on_drop($item->get_active);
}


sub sync_run_on_drop {
  my($self, $flag) = @_;

  my $path = '/Machine/Run when files dropped';
  my $item = $self->menu->get_widget($path) or return;
  return unless($item->get_active xor $flag);
  $item->set_active($flag);
}

1;

