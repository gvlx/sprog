package Sprog::GtkView::GearPalette;

use strict;

use Glib qw(TRUE FALSE);
use Gtk2::GladeXML;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app
  gladexml
  gearlist_model
  drag_index
));

use Scalar::Util qw(weaken);

use constant COL_TYPE => 0;

use constant COL_GEAR_INDEX => 0;
use constant COL_GEAR_CLASS => 1;

use constant ALPHA_THRESHOLD => 127;

my $palette = undef;

my $mini_icons;

my @connector_types = (
  'Any'    => '.',
  'None'   => '_',
  'Pipe'   => 'P',
  'List'   => 'A',
  'Record' => 'R',
);

my %type_map = @connector_types;

my @gear_classes = (   # Hardcoded for now - better idea coming soon
  {
    class    => 'Sprog::Gear::ReadFile',
    title    => 'Read File',
    type_in  => '_',
    type_out => 'P',
  },
  {
    class => 'Sprog::Gear::CommandIn',
    title    => 'Run Command',
    type_in  => '_',
    type_out => 'P',
  },
  {
    class => 'Sprog::Gear::Grep',
    title    => 'Pattern Match',
    type_in  => 'P',
    type_out => 'P',
  },
  {
    class => 'Sprog::Gear::FindReplace',
    title    => 'Find and Replace',
    type_in  => 'P',
    type_out => 'P',
  },
  {
    class => 'Sprog::Gear::PerlCode',
    title    => 'Perl Code',
    type_in  => 'P',
    type_out => 'P',
  },
  {
    class => 'Sprog::Gear::LowerCase',
    title    => 'Lowercase',
    type_in  => 'P',
    type_out => 'P',
  },
  {
    class => 'Sprog::Gear::UpperCase',
    title    => 'Uppercase',
    type_in  => 'P',
    type_out => 'P',
  },
  {
    class => 'Sprog::Gear::TextWindow',
    title    => 'Text Window',
    type_in  => 'P',
    type_out => '_',
  },
  {
    class => 'Sprog::Gear::CSVSplit',
    title    => 'CSV Split',
    type_in  => 'P',
    type_out => 'A',
  },
  {
    class => 'Sprog::Gear::ApacheLogParse',
    title    => 'Parse Apache Log',
    type_in  => 'P',
    type_out => 'H',
  },
  {
    class => 'Sprog::Gear::PerlCodeHP',
    title    => 'Perl Code',
    type_in  => 'H',
    type_out => 'P',
  },
);

sub new {
  my $class = shift;

  return $palette if $palette;

  $palette = bless { @_ }, $class;
  $palette->{app} && weaken($palette->{app});

  $mini_icons = Sprog::GtkView::Chrome::mini_icons();

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

  my $xml = $self->get_glade_xml                       || return;
  my $gladexml = Gtk2::GladeXML->new_from_buffer($xml) || return;
  $self->gladexml($gladexml);

  my $window = $self->{window} = $gladexml->get_widget('palette');

  $window->signal_connect(delete_event => sub { $self->app->hide_palette; } );

  $self->initialise_models($gladexml) &&
  $self->connect_signals($gladexml, $window);

  return $self->{window};
}


sub initialise_models {
  my($self, $gladexml) = @_;

  # Initialise combo boxes
  foreach my $menu_name (qw(input_menu output_menu)) {
    my $menu = $gladexml->get_widget($menu_name)
      or return $self->app->alert("Can't find input_menu combo");
    my $model = $menu->get_model
      or return $self->app->alert("input_menu combo has no storage");

    $model->clear;
    for(my $i = 0; $i < @connector_types; $i+=2) {
      my $iter = $model->append;
      $model->set($iter, COL_TYPE, $connector_types[$i]);
    }
    $menu->set_active(0);
  }

  # Set up model and columns for main listbox
  my $model = Gtk2::ListStore->new(
    'Glib::String',      # COL_GEAR_INDEX
    'Glib::String',      # COL_GEAR_CLASS
  );
  $self->gearlist_model($model);

  my $gearlist = $gladexml->get_widget('gear_list')
    or return $self->app->alert("Can't find gear_list listbox");

  $gearlist->set_model($model);
  $gearlist->set_rules_hint(TRUE);

  my($renderer, $column);
  $renderer = Gtk2::CellRendererPixbuf->new;
  $column   = Gtk2::TreeViewColumn->new;
  $column->pack_start($renderer, FALSE);
  $column->set_cell_data_func($renderer, sub { $self->set_item_pixbuf(@_); });
  $gearlist->append_column($column);

  $renderer = Gtk2::CellRendererText->new;
  $column   = Gtk2::TreeViewColumn->new_with_attributes (
    "Class",
    $renderer,
    text => COL_GEAR_CLASS,
  );
  $gearlist->append_column($column);

  $self->apply_filter;

  return 1;
}


sub set_item_pixbuf {
  my($self, $tree_column, $cell, $model, $iter) = @_;

  my($i) = $model->get($iter, COL_GEAR_INDEX);
  my $icon_type = $gear_classes[$i]->{type_in} . $gear_classes[$i]->{type_out};
  my $pixbuf = $mini_icons->{$icon_type} || $mini_icons->{__};
  $cell->set(pixbuf => $pixbuf);
}


sub connect_signals {
  my($self, $gladexml, $window) = @_;

  foreach my $menu_name (qw(input_menu output_menu)) {
    my $menu = $gladexml->get_widget($menu_name);
    $menu->signal_connect(changed => sub { $self->apply_filter(); });
  }

  my $button = $gladexml->get_widget('search');
  $button->signal_connect(clicked => sub { $self->reset_filter(); }); #TODO

  $button = $gladexml->get_widget('reset');
  $button->signal_connect(clicked => sub { $self->reset_filter(); });

  my $gearlist = $gladexml->get_widget('gear_list');
  $gearlist->signal_connect(
    cursor_changed => sub { $self->select_gear(@_);   }
  );
  $gearlist->signal_connect(
    drag_begin     => sub { $self->drag_begin(@_);    }
  );
  $gearlist->signal_connect(
    drag_data_get  => sub { $self->drag_data_get(@_); }
  );

}


sub apply_filter {
  my($self) = @_;

  $self->drag_index(undef);

  my $model = $self->gearlist_model;

  my $gladexml = $self->gladexml;

  my $menu_in = $gladexml->get_widget('input_menu');
  my $type_in = $connector_types[$menu_in->get_active * 2 + 1];

  my $menu_out = $gladexml->get_widget('output_menu');
  my $type_out = $connector_types[$menu_out->get_active * 2 + 1];

  my $types = qr/^$type_in$type_out/;
  my @matches = grep { "$gear_classes[$_]->{type_in}$gear_classes[$_]->{type_out}" =~ $types } (0..$#gear_classes);

  $model->clear;

  my $gearlist = $gladexml->get_widget('gear_list');
  if(@matches) {
    foreach my $i (@matches) {
      my $iter = $model->append;
      $model->set($iter, COL_GEAR_INDEX, $i);
      $model->set($iter, COL_GEAR_CLASS, $gear_classes[$i]->{title});
    }
    $gearlist->drag_source_set(
      ['button1_mask'], ['copy'], Sprog::GtkView::drag_targets()
    );
  }
  else {
    $gearlist->drag_source_unset;
  }

}


sub reset_filter {
  my($self, $menu) = @_;

  $self->app->not_implemented;
}


sub select_gear {
  my($self, $gearlist) = @_;

  my $selection = $gearlist->get_selection  || return;
  my($path) = $selection->get_selected_rows || return;
  $self->drag_index($path->to_string);
}


sub drag_begin {
  my($self, $gearlist, $context) = @_;

  my $i = $self->drag_index;
  return unless defined($i);

  my $icon_type = $gear_classes[$i]->{type_in} . $gear_classes[$i]->{type_out};
  my $pixbuf = $mini_icons->{$icon_type} || $mini_icons->{PP};
  my($drag_icon, $drag_mask) = $pixbuf->render_pixmap_and_mask(ALPHA_THRESHOLD);

  my $colormap = $self->window->get_colormap;

  $gearlist->drag_source_set_icon($colormap,  $drag_icon, $drag_mask);
}


sub drag_data_get {
  my($self, $gearlist, $context, $data, $info, $time) = @_;

  my $i = $self->drag_index;
  return unless defined($i);

  my $gear_class = $gear_classes[$i]->{class};
  $data->set($data->target, 8, $gear_class);
}


sub get_glade_xml {
  my $self = shift;

  my $xml = $self->glade_xml;

  if($xml =~ /^file:(.*)$/) {
    my $fh;
    unless(open $fh, '<', $1) {
      $self->app->alert("Error loading palette layout", "open($1): $!");
      return;
    }
    local($/);
    $xml = <$fh>;
  }

  return $xml;
}


sub glade_xml {
  my $self = shift;

#  return 'file:/home/grant/projects/sf/sprog/glade/palette.glade';
  return << 'END_XML';
<?xml version="1.0" standalone="no"?> <!--*- mode: xml -*-->
<!DOCTYPE glade-interface SYSTEM "http://glade.gnome.org/glade-2.0.dtd">

<glade-interface>

<widget class="GtkWindow" id="palette">
  <property name="width_request">500</property>
  <property name="height_request">420</property>
  <property name="visible">True</property>
  <property name="title" translatable="yes">Sprog Gear Palette</property>
  <property name="type">GTK_WINDOW_TOPLEVEL</property>
  <property name="window_position">GTK_WIN_POS_NONE</property>
  <property name="modal">False</property>
  <property name="resizable">True</property>
  <property name="destroy_with_parent">False</property>
  <property name="decorated">True</property>
  <property name="skip_taskbar_hint">False</property>
  <property name="skip_pager_hint">False</property>
  <property name="type_hint">GDK_WINDOW_TYPE_HINT_NORMAL</property>
  <property name="gravity">GDK_GRAVITY_NORTH_WEST</property>

  <child>
    <widget class="GtkVBox" id="vbox1">
      <property name="visible">True</property>
      <property name="homogeneous">False</property>
      <property name="spacing">0</property>

      <child>
	<widget class="GtkTable" id="table1">
	  <property name="border_width">4</property>
	  <property name="visible">True</property>
	  <property name="n_rows">4</property>
	  <property name="n_columns">5</property>
	  <property name="homogeneous">False</property>
	  <property name="row_spacing">0</property>
	  <property name="column_spacing">0</property>

	  <child>
	    <widget class="GtkLabel" id="label1">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Input Type:</property>
	      <property name="use_underline">False</property>
	      <property name="use_markup">False</property>
	      <property name="justify">GTK_JUSTIFY_LEFT</property>
	      <property name="wrap">False</property>
	      <property name="selectable">False</property>
	      <property name="xalign">0</property>
	      <property name="yalign">0.5</property>
	      <property name="xpad">0</property>
	      <property name="ypad">0</property>
	    </widget>
	    <packing>
	      <property name="left_attach">0</property>
	      <property name="right_attach">1</property>
	      <property name="top_attach">0</property>
	      <property name="bottom_attach">1</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkComboBox" id="input_menu">
	      <property name="visible">True</property>
	      <property name="items" translatable="yes">Filler Filler
</property>
	    </widget>
	    <packing>
	      <property name="left_attach">0</property>
	      <property name="right_attach">1</property>
	      <property name="top_attach">1</property>
	      <property name="bottom_attach">2</property>
	      <property name="x_options">fill</property>
	      <property name="y_options">fill</property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkEntry" id="search_entry">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="editable">True</property>
	      <property name="visibility">True</property>
	      <property name="max_length">0</property>
	      <property name="text" translatable="yes"></property>
	      <property name="has_frame">True</property>
	      <property name="invisible_char">*</property>
	      <property name="activates_default">False</property>
	    </widget>
	    <packing>
	      <property name="left_attach">2</property>
	      <property name="right_attach">3</property>
	      <property name="top_attach">1</property>
	      <property name="bottom_attach">2</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkButton" id="reset">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="label" translatable="yes">Reset</property>
	      <property name="use_underline">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <property name="focus_on_click">True</property>
	    </widget>
	    <packing>
	      <property name="left_attach">4</property>
	      <property name="right_attach">5</property>
	      <property name="top_attach">1</property>
	      <property name="bottom_attach">2</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkScrolledWindow" id="scrolledwindow1">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="hscrollbar_policy">GTK_POLICY_AUTOMATIC</property>
	      <property name="vscrollbar_policy">GTK_POLICY_AUTOMATIC</property>
	      <property name="shadow_type">GTK_SHADOW_IN</property>
	      <property name="window_placement">GTK_CORNER_TOP_LEFT</property>

	      <child>
		<widget class="GtkTreeView" id="gear_list">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="headers_visible">False</property>
		  <property name="rules_hint">False</property>
		  <property name="reorderable">False</property>
		  <property name="enable_search">False</property>
		</widget>
	      </child>
	    </widget>
	    <packing>
	      <property name="left_attach">0</property>
	      <property name="right_attach">5</property>
	      <property name="top_attach">2</property>
	      <property name="bottom_attach">3</property>
	      <property name="y_padding">4</property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="detail">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Drag a gear from the list and drop it on the Sprog workbench</property>
	      <property name="use_underline">False</property>
	      <property name="use_markup">False</property>
	      <property name="justify">GTK_JUSTIFY_CENTER</property>
	      <property name="wrap">False</property>
	      <property name="selectable">False</property>
	      <property name="xalign">0</property>
	      <property name="yalign">0.5</property>
	      <property name="xpad">0</property>
	      <property name="ypad">0</property>
	    </widget>
	    <packing>
	      <property name="left_attach">0</property>
	      <property name="right_attach">5</property>
	      <property name="top_attach">3</property>
	      <property name="bottom_attach">4</property>
	      <property name="x_options"></property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="label3">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Filter:</property>
	      <property name="use_underline">False</property>
	      <property name="use_markup">False</property>
	      <property name="justify">GTK_JUSTIFY_LEFT</property>
	      <property name="wrap">False</property>
	      <property name="selectable">False</property>
	      <property name="xalign">0</property>
	      <property name="yalign">0.5</property>
	      <property name="xpad">0</property>
	      <property name="ypad">0</property>
	    </widget>
	    <packing>
	      <property name="left_attach">2</property>
	      <property name="right_attach">5</property>
	      <property name="top_attach">0</property>
	      <property name="bottom_attach">1</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkComboBox" id="output_menu">
	      <property name="visible">True</property>
	      <property name="items" translatable="yes">Filler Filler</property>
	    </widget>
	    <packing>
	      <property name="left_attach">1</property>
	      <property name="right_attach">2</property>
	      <property name="top_attach">1</property>
	      <property name="bottom_attach">2</property>
	      <property name="x_padding">10</property>
	      <property name="x_options">fill</property>
	      <property name="y_options">fill</property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="label2">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Output Type:</property>
	      <property name="use_underline">False</property>
	      <property name="use_markup">False</property>
	      <property name="justify">GTK_JUSTIFY_LEFT</property>
	      <property name="wrap">False</property>
	      <property name="selectable">False</property>
	      <property name="xalign">0</property>
	      <property name="yalign">0.5</property>
	      <property name="xpad">0</property>
	      <property name="ypad">0</property>
	    </widget>
	    <packing>
	      <property name="left_attach">1</property>
	      <property name="right_attach">2</property>
	      <property name="top_attach">0</property>
	      <property name="bottom_attach">1</property>
	      <property name="x_padding">10</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkButton" id="search">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="label" translatable="yes">Search</property>
	      <property name="use_underline">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <property name="focus_on_click">True</property>
	    </widget>
	    <packing>
	      <property name="left_attach">3</property>
	      <property name="right_attach">4</property>
	      <property name="top_attach">1</property>
	      <property name="bottom_attach">2</property>
	      <property name="x_padding">4</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>
	</widget>
	<packing>
	  <property name="padding">0</property>
	  <property name="expand">True</property>
	  <property name="fill">True</property>
	</packing>
      </child>
    </widget>
  </child>
</widget>

</glade-interface>
END_XML
}


1;

