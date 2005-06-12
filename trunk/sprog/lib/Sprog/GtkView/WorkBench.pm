package Sprog::GtkView::WorkBench;

use strict;
use warnings;

use base qw(Sprog::Accessor);

__PACKAGE__->mk_accessors(qw(
  app
  view
  canvas
  widget
));

use Scalar::Util qw(weaken);

use Glib qw(TRUE FALSE);
use Gnome2::Canvas;

use Sprog::GtkView::DnD qw(
  SPROG_GEAR_TARGET TARG_SPROG_GEAR_CLASS DRAG_FILES_TARGET
);


sub new {
  my $class = shift;

  my $self = bless {
    @_,
    gears => {},
  }, $class;
  weaken($self->{app});
  weaken($self->{view});

  my $app = $self->app;
  $app->inject('/app/view/gearview' => 'Sprog::GtkGearView');
  $app->load_class('/app/view/gearview');

  $self->_build_workbench;

  return $self;
}


sub _build_workbench {
  my($self) = @_;

  my $sw = $self->widget(Gtk2::ScrolledWindow->new);
  $sw->set_policy('automatic', 'automatic');

  my $canvas = Gnome2::Canvas->new_aa;
  $self->canvas($canvas);
#  $canvas->signal_connect(size_allocate => sub { $self->_reset_canvas_scroll_region; });

  $sw->add($canvas);

  my $color = Gtk2::Gdk::Color->parse("#007f00");
  $canvas->modify_bg('normal', $color);

  $canvas->set_scroll_region(0, 0, 400, 300);

  # Set up as target for drag-n-drop

  $canvas->drag_dest_set('all', ['copy'], SPROG_GEAR_TARGET, DRAG_FILES_TARGET);
  $canvas->signal_connect(
    drag_data_received => sub { $self->drag_data_received(@_); }
  );

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


sub drag_data_received {
  my($self, $canvas, $context, $x, $y, $data, $info, $time) = @_;

  my $msg_type = $data->type->name;

  if(($data->length < 1) || ($data->format != 8)) {
    $context->finish (0, 0, $time);
    return
  }

  my $msg_body = $data->data;
  $context->finish (1, 0, $time);

  if($msg_type eq 'application/x-sprog-gear-class') {
    $self->_drop_gear_class($msg_body, $canvas, $x, $y);
  }
  elsif($msg_type eq 'text/plain') {
    $self->_drop_uris($msg_body);
  }

  return;
}


sub _drop_gear_class {
  my($self, $gear_class, $canvas, $x, $y) = @_;

  my $gear = $self->app->add_gear_at_x_y($gear_class, $x, $y) or return;
  my $gearview = $self->gear_view_by_id($gear->id);

  my($cx, $cy) = $canvas->window_to_world($x, $y);
  $self->app->drop_gear($gearview, $cx, $cy);
}


sub _drop_uris {
  my($self, $data) = @_;

  if($data !~ /^\w+:/) {
    $self->app->alert(
      'Drag-and-drop error',
      "Expected a list of files or URIs, received:\n$data"
    );
    return;
  }

  my @uris = map { /\S/ ? $_ : () } split /[\r\n]/, $data;

  $self->app->dnd_drop_uris(@uris);
}


sub turn_cogs {
  my $self = shift;

  foreach my $gear_view (values %{$self->{gears}}) {
    my $gear = $gear_view->gear;
    if($gear->work_done) {
      $gear_view->turn_cog;
      $gear->work_done(0);
    }
  }
  return TRUE;
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


sub update_gear_view {
  my($self, $id) = @_;

  my $gearview = $self->{gears}->{$id} or return;
  $gearview->update_view;
};


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


1;
