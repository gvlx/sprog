package Sprog::GtkView::Toolbar;

use strict;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app
  widget
));

use Scalar::Util qw(weaken);

use Gtk2 '-init';
use Glib qw(TRUE FALSE);

use constant APPEND => -1;

sub new {
  my $class = shift;

  my $self = bless { @_, }, $class;
  $self->{app} && weaken($self->{app});

  $self->build_toolbar;

  return $self;
}


sub build_toolbar {
  my $self = shift;

  my $toolbar = Gtk2::Toolbar->new;
  $self->widget($toolbar);

  $toolbar->set_style('icons');

  my $app = $self->app;

  $self->{'new'} = $toolbar->insert_stock(
    'gtk-new',
    'Create a new machine',
    undef,
    sub { $app->file_new },
    undef,
    APPEND
  );

  $self->{'open'} = $toolbar->insert_stock(
    'gtk-open',
    'Load a machine from a file',
    undef,
    sub { $app->file_open },
    undef,
    APPEND
  );

  $self->{'save'} = $toolbar->insert_stock(
    'gtk-save',
    'Save current machine to a file',
    undef,
    sub { $app->file_save },
    undef,
    APPEND
  );

  $toolbar->append_space;

  my $pbutton = Gtk2::Image->new_from_stock('gtk-add', 'large-toolbar');
  $self->{'palette'} = $toolbar->append_element(
    'togglebutton',
    undef,  # No widget
    undef,  # No text
    'Add parts to the machine',
    undef,  # No private text
    $pbutton,
    sub { $app->toggle_palette; },
  );

  $toolbar->append_space;

  $self->{'run'} = $toolbar->insert_stock(
    'gtk-execute',
    'Run the machine',
    undef,
    sub { $app->run_machine },
    undef,
    APPEND
  );

  $self->{'stop'} = $toolbar->insert_stock(
    'gtk-stop',
    'Stop the machine',
    undef,
    sub { $app->stop_machine },
    undef,
    APPEND
  );
  $self->set_sensitive('stop' => FALSE);

}


sub set_palette_active {
  my($self, $state) = @_;

  my $button = $self->{palette} || return;
  $button->set_active($state);
}


sub set_sensitive {
  my($self, $name, $state) = @_;

  my $button = $self->{$name} || return;
  $button->set(sensitive => $state);
}

1;

