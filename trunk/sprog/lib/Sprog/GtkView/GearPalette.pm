package Sprog::GtkView::GearPalette;

use strict;

use Glib qw(TRUE FALSE);

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app
));

use Scalar::Util qw(weaken);

my $palette = undef;

sub new {
  my $class = shift;

  return $palette if $palette;

  $palette = bless { @_ }, $class;
  $palette->{app} && weaken($palette->{app});

  return $palette;
}


sub show {
  my($class, $app) = @_;

  my $self = $class->new(app => $app);

  my $window = $self->window();

  $window->show;
}


sub toggle {
  my $class = shift;

  if($palette  and  $palette->window->visible) {
    $palette->hide();
    return 0;
  }
  $class->show(@_);
  return 1;
}


sub hide {
  return unless($palette  and  $palette->{window});

  $palette->window->hide;

  return TRUE;
}


sub window {
  my($self) = @_;

  return $self->{window} if $self->{window};

  my $window = $self->{window} = Gtk2::Window->new();
  $window->set_title('Sprog Gear Palette');
  $window->set_default_size (450, 320);

  $window->signal_connect(delete_event => sub { $self->app->hide_palette; });
  
  my $label = Gtk2::Label->new('Palette Window');
  $window->add($label);

  $window->show_all;

  return $window;
}


1;

