package Sprog::GtkView::GearPalette;

use strict;

use Glib qw(TRUE FALSE);
use Gtk2::GladeXML;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app
  gladexml
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

  my $xml = $self->get_glade_xml                       || return;
  my $gladexml = Gtk2::GladeXML->new_from_buffer($xml) || return;
  $self->gladexml($gladexml);

  $self->{window} = $gladexml->get_widget('palette');
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

