package Pstax::GtkGearView;

use strict;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app
  gear
  group
  last_mouse_x
  last_mouse_y
  dragging
));

use Scalar::Util qw(weaken);

use Glib qw(TRUE FALSE);

use Pstax::GtkGearView::Paths;
use Pstax::GtkAutoDialog;

*gear_width  = \&Pstax::GtkGearView::Paths::gBW;
*gear_height = \&Pstax::GtkGearView::Paths::gBH;
*gCW = \&Pstax::GtkGearView::Paths::gCW;
*gCH = \&Pstax::GtkGearView::Paths::gCH;

sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;
  $self->{app} && weaken($self->{app});
  return $self;
}


sub add_gear {
  my($class, $app, $canvas, $gear) = @_;

  my $root  = $canvas->root;

  my $group = Gnome2::Canvas::Item->new(
    $root, 
    'Gnome2::Canvas::Group',
    x         => 0, 
    y         => 0,
    user_data => $gear->id,
  );
  
  my $self = $class->new_gear_view($app, $gear, $group) || return;

  my $shape = Pstax::GtkGearView::Paths->gear_path($gear);

  my $block = Gnome2::Canvas::Item->new(
    $group,
    'Gnome2::Canvas::Bpath',
    outline_color => 'black',
    fill_color    => '#c9c9c9',
    width_pixels  => 2,
    cap_style     => 'round'
  );
  $block->set_path_def($shape);

  $self->add_title($group, $gear);
  $self->init_cog_frames($group);

  $group->signal_connect(event => sub { $self->event(@_) });
  $self->move(100,80);

  return $self;
}


sub new_gear_view {
  my($class, $app, $gear, $group) = @_;

  my $gear_view = eval {
    my $suffix = $gear->view_subclass;
    if($suffix) {
      $class .= '::' . $suffix;
      $app->require_class($class);
    }

    $class->new(
      app    => $app,
      gear   => $gear,
      group  => $group,
    );
  };
  if($@) {
    $app->alert("Unable to create a $class object", $@);
    undef($@);
    return;
  }

  return $gear_view;
}


sub add_title {
  my($self, $group, $gear) = @_;

  my $text = $gear->title || return;
  my $text_x = &gCW * 3.6;
  my $text_y = &gear_height / 2;
  my $label = Gnome2::Canvas::Item->new(
    $group,
    'Gnome2::Canvas::Text',
    fill_color    => 'black',
    x             => $text_x,
    y             => $text_y,
    family        => 'sans',
    size_points   => 15,
    justification => 'center',
    text          => $text,
  );
  my $text_w = $label->get('text_width');
  $label->set('x' => $text_x + $text_w / 2);  # Simulate left alignment
}


sub init_cog_frames {
  my($self, $group) = @_;

  my @frames = map {
    Gnome2::Canvas::Item->new(
      $group,
      'Gnome2::Canvas::Pixbuf',
      pixbuf => $_,
      x      => &gCW * 2.8,
      y      => &gear_height / 2,
      width  => $_->get_width,
      height => $_->get_height,
      anchor => 'center',
    );
  } Pstax::GtkViewChrome->cogs;

  $self->{cog_frames} = \@frames;
  $self->{cog_index}  = 0;

  $_->hide foreach (@frames);
  $frames[0]->show;
}


sub turn_cog {
  my $self = shift;

  my $i = $self->{cog_index};
  my $j = $self->{cog_index} = ($i + 1) % @{$self->{cog_frames}};
  $self->{cog_frames}->[$j]->show;
  $self->{cog_frames}->[$i]->hide;
}


sub move {
  my($self, $dx, $dy) = @_;

  my $group = $self->group;
  $group->move($dx, $dy);
  
  my $gear = $self->gear;
  $gear->x($gear->x + $dx);
  $gear->y($gear->y + $dy);

  my $next = $gear->next || return;
  my $next_view = $self->app->view->gear_view_by_id($next->id);
  $next_view->move($dx, $dy);
}


sub event {
  my($self, $item, $event) = @_;

  my($item_x, $item_y);
  ($item_x, $item_y) = $item->parent->w2i($event->coords) if $event->coords;
  my $type = $event->type;

  if($type eq 'button-press'  and  $event->button == 3) {
    $self->post_context_menu;
  }
  elsif($type eq 'button-press'  and  $event->button == 1) {
    $self->app->detach_gear($self->gear);
    $item->raise_to_top;
    $self->last_mouse_x($item_x);
    $self->last_mouse_y($item_y);

    $item->grab(
      [qw(pointer-motion-mask button-release-mask)],
      Gtk2::Gdk::Cursor->new('fleur'),
      $event->time
    );

    $self->dragging(TRUE);
  }
  elsif($type eq 'motion-notify') {
    if($self->dragging && $event->state >= 'button1-mask') {
      my $new_x = $item_x;
      my $new_y = $item_y;

      return if(!defined($new_x) || !defined($new_y));

      $self->move($new_x - $self->last_mouse_x, $new_y - $self->last_mouse_y);
      $self->last_mouse_x($new_x);
      $self->last_mouse_y($new_y);
    }
  }
  elsif($type eq 'button-release' and $self->dragging) {
    $item->ungrab($event->time);
    $self->dragging(FALSE);
    my($x, $y) = $item->get_bounds;
    $self->app->drop_gear($self, $x, $y);
  }

}


sub delete_view {
  my $self = shift;

  $self->gear(undef);
  $self->group->destroy;  # Is this kocher?
}


sub post_context_menu {
  my $self = shift;

  my $menu = Gtk2::Menu->new;

  foreach my $item (@{$self->context_menu_entries}) {
    my $menu_item = new Gtk2::MenuItem($item->{title});
    $menu_item->signal_connect('activate', $item->{callback});
    $menu->append($menu_item);
    $menu_item->set(sensitive => FALSE) if $item->{disabled};
    $menu_item->show;
  }

  $menu->popup(undef, undef, \&menu_pos, undef, 3, 0);
}


sub context_menu_entries {
  my $self = shift;

  return [
    {
      title    => 'Delete',
      callback => sub { $self->app->delete_gear_by_id($self->gear->id); },
      disabled => FALSE,
    },
    {
      title    => 'Properties',
      callback => sub { $self->properties; },
      disabled => $self->gear->no_properties,
    },
  ];
}


sub menu_pos {
  my($menu, $x, $y, $data) = @_;

  return($x-2, $y-2);
}


sub properties {
  my $self = shift;

  return if $self->auto_properties;
  $self->app->not_implemented;
}


sub auto_properties {
  my $self = shift;

  return Pstax::GtkAutoDialog->invoke(gearview => $self);
}


sub dialog_xml {
  my $self = shift;

  my $gear = $self->gear;
  return unless $gear->can('dialog_xml');

  my $xml = $gear->dialog_xml;

  if($xml =~ /^file:(.*)$/) {
    my $fh;
    unless(open $fh, '<', $1) {
      $self->app->alert("Can't get properties dialog", "open($1): $!");
      return;
    }
    local($/);
    $xml = <$fh>;
  }

  return $xml;
}


sub dialog_name {
  my $gear = shift->gear;

  return $gear->can('dialog_name') ? $gear->dialog_name : 'properties';
}


sub app_win {
  my $self = shift;

  my $canvas = $self->group->canvas || return;
  return $canvas->get_toplevel;
}


sub dump {
  my($self) = @_;

  my $id = $self->gear->id;
  my $class = ref($self);
  print "$id: $class\n";
  $self->gear->dump;
}


sub _valu { my $val = shift; defined $val ? "'$val'" : 'undef'; }


1;


