package Sprog::GtkView::Palette;

use strict;

use Glib qw(TRUE FALSE);

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app
  view
  widget
  input_combo
  output_combo
  search_entry
  search_button
  gearlist
  gearlist_model
  filtered_list
  selected_class
));

use Scalar::Util qw(weaken);

use constant COL_TYPE => 0;

use constant COL_GEAR_CLASS => 0;
use constant COL_GEAR_TITLE => 1;

use constant ALPHA_THRESHOLD => 127;

my $mini_icons;

my @connector_types;


sub new {
  my $class = shift;

  my $self = bless { @_, filtered_list => [] }, $class;
  weaken($self->{app});
  weaken($self->{view});

  if(!@connector_types) {
    @connector_types = $self->{app}->geardb->connector_types;
  }

  unless(defined($mini_icons)) {
    $mini_icons = $self->{view}->chrome_class->mini_icons();
  }

  $self->_build_widget;

  $self->_apply_filter;

  return $self;
}


sub _apply_filter {
  my $self = shift;

  $self->selected_class(undef);

  my $type_in  = $connector_types[$self->input_combo->get_active  * 2 + 1];
  my $type_out = $connector_types[$self->output_combo->get_active * 2 + 1];
  my $keyword  = $self->search_entry->get_text || '';
  
  my @matches = $self->app->geardb->search($type_in, $type_out, $keyword);
  $self->filtered_list(\@matches);

  my $model = $self->gearlist_model;
  $model->clear;

  if(@matches) {
    foreach (@matches) {
      my $iter = $model->append;
      $model->set($iter, COL_GEAR_CLASS, $_->{class});
      $model->set($iter, COL_GEAR_TITLE, $_->{title});
    }
    $self->gearlist->drag_source_set(
      ['button1_mask'], ['copy'], $self->view->drag_targets()
    );
  }
  else {
    $self->gearlist->drag_source_unset;
  }

}


sub _reset_filter {
  my $self = shift;

  $self->search_entry->set_text('');
  $self->_apply_filter;
}


sub _build_widget {
  my $self = shift;

  my $frame = Gtk2::Frame->new;
  $frame->set_shadow_type('in');
  $self->widget($frame);

  my $vbox = Gtk2::VBox->new;
  $frame->add($vbox);

  $vbox->pack_start($self->_build_combos,    FALSE, TRUE, 0);
  $vbox->pack_start($self->_build_searchbox, FALSE, TRUE, 0);
  $vbox->pack_start($self->_build_gearlist,  TRUE, TRUE, 0);

  my $label = Gtk2::Label->new;
  $label->set_markup(
    "<small>Drag a gear from the list and\n" .
    "drop it in the Sprog workspace</small>"
  );
  $label->set_justify('center');
  $vbox->pack_start($label, FALSE, TRUE, 0);

  $frame->show_all;
}


sub _build_combos {
  my $self = shift;

  my $table = Gtk2::Table->new(2, 2, FALSE);

  my $label_in = Gtk2::Label->new;
  $label_in->set_markup('<small>Connector In:</small>');
  $label_in->set_justify('left');
  $table->attach($label_in, 0, 1, 0, 1, ['expand', 'fill'], ['fill'], 4, 2);

  my $label_out = Gtk2::Label->new;
  $label_out->set_markup('<small>Connector Out:</small>');
  $label_out->set_justify('left');
  $table->attach($label_out, 1, 2, 0, 1, ['expand', 'fill'], ['fill'], 4, 2);

  my $combo_in = Gtk2::ComboBox->new_text;
  $self->input_combo($combo_in);
  for(my $i = 0; $i < @connector_types; $i+=2) {
    $combo_in->append_text($connector_types[$i]);
  }
  $combo_in->set_active(0);
  $combo_in->signal_connect(changed => sub { $self->_apply_filter(); });
  $table->attach($combo_in, 0, 1, 1, 2, ['expand', 'fill'], ['fill'], 4, 2);

  my $combo_out = Gtk2::ComboBox->new_text;
  $self->output_combo($combo_out);
  for(my $i = 0; $i < @connector_types; $i+=2) {
    $combo_out->append_text($connector_types[$i]);
  }
  $combo_out->set_active(0);
  $combo_out->signal_connect(changed => sub { $self->_apply_filter(); });
  $table->attach($combo_out, 1, 2, 1, 2, ['expand', 'fill'], ['fill'], 4, 2);

  return $table;
}


sub _build_searchbox {
  my $self = shift;

  my $table = Gtk2::Table->new(1, 3, FALSE);
  
  my $entry = Gtk2::Entry->new;
  $entry->set_width_chars(11);
  $entry->set('activates-default' => TRUE);
  $self->search_entry($entry);
  $table->attach($entry, 0, 1, 0, 1, ['expand', 'fill'], ['fill'], 4, 2);
  
  my $search_btn = Gtk2::Button->new('Search');
  $search_btn->can_default(TRUE);
  $search_btn->signal_connect(clicked => sub { $self->_apply_filter; });
  $self->search_button($search_btn);
  $table->attach($search_btn, 1, 2, 0, 1, ['fill'], ['fill'], 0, 2);

  my $clear_btn = Gtk2::Button->new('Clear');
  $clear_btn->signal_connect(clicked => sub { $self->_reset_filter; });
  $table->attach($clear_btn, 2, 3, 0, 1, ['fill'], ['fill'], 4, 2);

  return $table;
}


sub _build_gearlist {
  my $self = shift;

  my $model = Gtk2::ListStore->new(
    'Glib::String',      # COL_GEAR_CLASS
    'Glib::String',      # COL_GEAR_TITLE
  );
  $self->gearlist_model($model);

  my $gearlist = Gtk2::TreeView->new;
  $self->gearlist($gearlist);
  $gearlist->set_headers_visible(FALSE);
  $gearlist->set_model($model);
  $gearlist->set_rules_hint(TRUE);

  my($renderer, $column);
  $renderer = Gtk2::CellRendererPixbuf->new;
  $column   = Gtk2::TreeViewColumn->new;
  $column->pack_start($renderer, FALSE);
  $column->set_cell_data_func($renderer, sub { $self->_set_item_pixbuf(@_); });
  $gearlist->append_column($column);

  $renderer = Gtk2::CellRendererText->new;
  $column   = Gtk2::TreeViewColumn->new_with_attributes (
    "Gear Name",
    $renderer,
    text => COL_GEAR_TITLE,
  );
  $gearlist->append_column($column);


  $gearlist->signal_connect(
    cursor_changed => sub { $self->_select_gear(@_);   }
  );
  $gearlist->signal_connect(
    drag_begin     => sub { $self->_drag_begin(@_);    }
  );
  $gearlist->signal_connect(
    drag_data_get  => sub { $self->_drag_data_get(@_); }
  );

  my $sw = Gtk2::ScrolledWindow->new;
  $sw->set_policy ('automatic', 'automatic');
  $sw->add($gearlist);

  return $sw;
}


sub _set_item_pixbuf {
  my($self, $tree_column, $cell, $model, $iter) = @_;

  my($class) = $model->get($iter, COL_GEAR_CLASS);
  my $info = $self->app->geardb->gear_class_info($class);

  my $icon_type = $info->{type_in} . $info->{type_out};
  my $pixbuf = $mini_icons->{$icon_type} || $mini_icons->{__};
  $cell->set(pixbuf => $pixbuf);
}


sub _select_gear {
  my($self, $gearlist) = @_;

  my $selection = $gearlist->get_selection  || return;
  my($path) = $selection->get_selected_rows || return;
  my $info = $self->filtered_list->[$path->to_string] || {};
  $self->selected_class($info->{class});
}


sub _drag_begin {
  my($self, $gearlist, $context) = @_;

  my $class = $self->selected_class or return;
  my $info  = $self->app->geardb->gear_class_info($class);

  my $icon_type = $info->{type_in} . $info->{type_out};
  my $pixbuf = $mini_icons->{$icon_type} || $mini_icons->{PP};
  my($drag_icon, $drag_mask) = $pixbuf->render_pixmap_and_mask(ALPHA_THRESHOLD);

  my $colormap = $self->widget->get_colormap;

  $gearlist->drag_source_set_icon($colormap,  $drag_icon, $drag_mask);
}


sub _drag_data_get {
  my($self, $gearlist, $context, $data, $info, $time) = @_;

  my $class = $self->selected_class or return;

  $data->set($data->target, 8, $class);
}


1;

