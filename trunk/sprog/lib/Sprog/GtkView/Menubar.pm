package Sprog::GtkView::Menubar;

use strict;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app
  menu
));

use Scalar::Util qw(weaken);

use Gtk2 '-init';
use Glib qw(TRUE FALSE);

use constant TOOLBAR_STYLE => 1;

sub new {
  my $class = shift;

  my $self = bless { @_, }, $class;
  $self->{app} && weaken($self->{app});

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
        '_Toolbar Style' => {
            item_type  => '<Branch>',
            children => [
                'I_cons and Text' => {
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
      ],
    },
    _Help  => {
      item_type  => '<Branch>',
      children => [
        _About => {
          callback        => sub { $app->help_about },
          callback_action => $action++,
        },
      ],
    },
  ];

  $self->menu(Gtk2::SimpleMenu->new(menu_tree => $menu_tree));
}

sub accel_group { shift->menu->{accel_group} };
sub widget      { shift->menu->{widget} };

sub set_palette_active {
  my($self, $state) = @_;

  my $item = $self->menu->get_widget('/View/Palette') || return;
  $item->set_active($state);
}

1;

