package Sprog::GtkView::PrefsDialog;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2::GladeXML;

use base qw(
  Sprog::Accessor
);

__PACKAGE__->mk_accessors(qw(
  app dialog
  priv_gear_entry
  bg_colour_button
  font_gear_title
  font_text_window
));

use Scalar::Util qw(weaken);

use constant HELP_TOPIC => 'Sprog::help::preferences';


sub invoke {
  my($class, $app) = @_;

  my $self = $class->new(app => $app);

  my $dialog = $self->dialog or return;

  while(my $resp = $dialog->run) {
#    if($resp eq 'help') {
#      my $topic = $self->gearview->gear_class;
#      $self->app->show_help(HELP_TOPIC);
#      next;
#    }
    last if($resp eq 'cancel');
    if($resp eq 'ok') {
      last if $self->save
    }
  }

  $dialog->destroy;
}


sub new { 
  my $class = shift;

  my $self = bless({ @_ }, $class);
  weaken($self->{app});

  return $self->_init;
}


sub _init {
  my $self = shift;

  my $glade_src = $self->glade_xml;
  my $gladexml = Gtk2::GladeXML->new_from_buffer($glade_src);

  $self->dialog($gladexml->get_widget('preferences'));

  my $app  = $self->app;

  my $priv_path = $app->get_pref('private_gear_folder') || '';
  my $entry = $self->priv_gear_entry($gladexml->get_widget('private_gear_folder'));
  $entry->set_text($priv_path);

  my $bg_clr = $app->get_pref('workbench.bg_colour') || 
    $app->view->workbench->default_bg_colour;
  my $bg_btn = $self->bg_colour_button($gladexml->get_widget('bg_colour_button'));
  my $colour = Gtk2::Gdk::Color->parse($bg_clr);
  $bg_btn->set_color($colour);

  my $fb_gear_title = $self->font_gear_title($gladexml->get_widget('font_gear_title'));
  if(my $font = $app->get_pref('gearview.title_font')) {
    $fb_gear_title->set_font_name($font);
  }
  my $fb_text_win   = $self->font_text_window($gladexml->get_widget('font_text_window'));

  $gladexml->signal_autoconnect(
    sub { $self->autoconnect(@_) }
  );

  return $self;
}


sub autoconnect {
  my($self, $method, $widget, $signal) = @_;

  die __PACKAGE__ . " has no $method method"
    unless $self->can($method);
    
  $widget->signal_connect(
    $signal => sub { $self->$method(@_) }
  );
}


sub on_browse_clicked {
  my($self) = @_;

  my $file_chooser = Gtk2::FileChooserDialog->new(
    'Select Folder',
    undef,
    'select-folder',
    'gtk-cancel' => 'cancel',
    'gtk-ok'     => 'ok'
  );
  if($file_chooser->run eq 'ok') {
    my $folder = $file_chooser->get_filename;
    my $entry  = $self->priv_gear_entry or return;
    $entry->set_text($folder);
  }
  $file_chooser->destroy;

}


sub save {
  my($self) = @_;

  my $app = $self->app or return;

  my $entry  = $self->priv_gear_entry;
  my $folder = $entry->get_text;

  if(length($folder)  and  !-d $folder) {
    $app->confirm_yes_no(
      'Make folder?',
      "Folder $folder does not exist.\nDo you wish to create it?"
    ) or return;
    mkdir($folder) or
      return $app->alert("Error creating folder", "mkdir($folder): $!");
  }
  $app->set_pref('private_gear_folder', $folder);
  $app->init_private_path;  # refresh palette view

  my $bg_btn = $self->bg_colour_button;
  my $bg_clr = $bg_btn->get_color;
  my $bg_rgb = sprintf("#%04X%04X%04X", map { $bg_clr->$_ } qw(red green blue));
  $app->set_pref('workbench.bg_colour', $bg_rgb);
  $app->view->workbench->set_bg_colour;

  my $fb_gear_title = $self->font_gear_title;
  my $font = $fb_gear_title->get_font_name;
  $app->set_pref('gearview.title_font', $font);
  $app->view->set_gear_title_font($font);

  return 1;
}


sub glade_xml {
  return `cat /home/grant/projects/sf/sprog/glade/preferences.glade`;
  return <<'END_XML';
<?xml version="1.0" standalone="no"?> <!--*- mode: xml -*-->
<!DOCTYPE glade-interface SYSTEM "http://glade.gnome.org/glade-2.0.dtd">

<glade-interface>

<widget class="GtkDialog" id="preferences">
  <property name="title" translatable="yes">Preferences</property>
  <property name="type">GTK_WINDOW_TOPLEVEL</property>
  <property name="window_position">GTK_WIN_POS_MOUSE</property>
  <property name="modal">False</property>
  <property name="default_width">380</property>
  <property name="resizable">True</property>
  <property name="destroy_with_parent">True</property>
  <property name="decorated">True</property>
  <property name="skip_taskbar_hint">True</property>
  <property name="skip_pager_hint">True</property>
  <property name="type_hint">GDK_WINDOW_TYPE_HINT_DIALOG</property>
  <property name="gravity">GDK_GRAVITY_NORTH_WEST</property>
  <property name="has_separator">True</property>

  <child internal-child="vbox">
    <widget class="GtkVBox" id="dialog-vbox1">
      <property name="visible">True</property>
      <property name="homogeneous">False</property>
      <property name="spacing">0</property>

      <child internal-child="action_area">
	<widget class="GtkHButtonBox" id="dialog-action_area1">
	  <property name="visible">True</property>
	  <property name="layout_style">GTK_BUTTONBOX_END</property>

	  <child>
	    <widget class="GtkButton" id="cancelbutton1">
	      <property name="visible">True</property>
	      <property name="can_default">True</property>
	      <property name="can_focus">True</property>
	      <property name="label">gtk-cancel</property>
	      <property name="use_stock">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <property name="focus_on_click">True</property>
	      <property name="response_id">-6</property>
	    </widget>
	  </child>

	  <child>
	    <widget class="GtkButton" id="okbutton1">
	      <property name="visible">True</property>
	      <property name="can_default">True</property>
	      <property name="has_default">True</property>
	      <property name="can_focus">True</property>
	      <property name="label">gtk-ok</property>
	      <property name="use_stock">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <property name="focus_on_click">True</property>
	      <property name="response_id">-5</property>
	    </widget>
	  </child>
	</widget>
	<packing>
	  <property name="padding">0</property>
	  <property name="expand">False</property>
	  <property name="fill">True</property>
	  <property name="pack_type">GTK_PACK_END</property>
	</packing>
      </child>

      <child>
	<widget class="GtkNotebook" id="notebook1">
	  <property name="visible">True</property>
	  <property name="can_focus">True</property>
	  <property name="show_tabs">True</property>
	  <property name="show_border">False</property>
	  <property name="tab_pos">GTK_POS_TOP</property>
	  <property name="scrollable">False</property>
	  <property name="enable_popup">False</property>

	  <child>
	    <widget class="GtkTable" id="table1">
	      <property name="border_width">10</property>
	      <property name="visible">True</property>
	      <property name="n_rows">4</property>
	      <property name="n_columns">2</property>
	      <property name="homogeneous">False</property>
	      <property name="row_spacing">2</property>
	      <property name="column_spacing">4</property>

	      <child>
		<widget class="GtkLabel" id="label3">
		  <property name="visible">True</property>
		  <property name="label" translatable="yes">Personal gear folder</property>
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
		  <property name="right_attach">2</property>
		  <property name="top_attach">0</property>
		  <property name="bottom_attach">1</property>
		  <property name="x_options">fill</property>
		  <property name="y_options"></property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkEntry" id="private_gear_folder">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="editable">True</property>
		  <property name="visibility">True</property>
		  <property name="max_length">0</property>
		  <property name="text" translatable="yes"></property>
		  <property name="has_frame">True</property>
		  <property name="invisible_char">*</property>
		  <property name="activates_default">True</property>
		</widget>
		<packing>
		  <property name="left_attach">0</property>
		  <property name="right_attach">1</property>
		  <property name="top_attach">1</property>
		  <property name="bottom_attach">2</property>
		  <property name="y_options"></property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkButton" id="browse">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Browse</property>
		  <property name="use_underline">True</property>
		  <property name="relief">GTK_RELIEF_NORMAL</property>
		  <property name="focus_on_click">True</property>
		  <signal name="clicked" handler="on_browse_clicked" last_modification_time="Sat, 25 Jun 2005 22:50:46 GMT"/>
		</widget>
		<packing>
		  <property name="left_attach">1</property>
		  <property name="right_attach">2</property>
		  <property name="top_attach">1</property>
		  <property name="bottom_attach">2</property>
		  <property name="x_options">fill</property>
		  <property name="y_options"></property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkColorButton" id="bg_colour_button">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="use_alpha">False</property>
		  <property name="focus_on_click">True</property>
		</widget>
		<packing>
		  <property name="left_attach">1</property>
		  <property name="right_attach">2</property>
		  <property name="top_attach">3</property>
		  <property name="bottom_attach">4</property>
		  <property name="x_options">fill</property>
		  <property name="y_options"></property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkLabel" id="label4">
		  <property name="visible">True</property>
		  <property name="label" translatable="yes">Workspace background colour</property>
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
		  <property name="top_attach">3</property>
		  <property name="bottom_attach">4</property>
		  <property name="x_options">fill</property>
		  <property name="y_options"></property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkHSeparator" id="hseparator1">
		  <property name="visible">True</property>
		</widget>
		<packing>
		  <property name="left_attach">0</property>
		  <property name="right_attach">2</property>
		  <property name="top_attach">2</property>
		  <property name="bottom_attach">3</property>
		  <property name="y_padding">10</property>
		  <property name="x_options">fill</property>
		  <property name="y_options">fill</property>
		</packing>
	      </child>
	    </widget>
	    <packing>
	      <property name="tab_expand">False</property>
	      <property name="tab_fill">True</property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="label1">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Paths</property>
	      <property name="use_underline">False</property>
	      <property name="use_markup">False</property>
	      <property name="justify">GTK_JUSTIFY_LEFT</property>
	      <property name="wrap">False</property>
	      <property name="selectable">False</property>
	      <property name="xalign">0.5</property>
	      <property name="yalign">0.5</property>
	      <property name="xpad">0</property>
	      <property name="ypad">0</property>
	    </widget>
	    <packing>
	      <property name="type">tab</property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkTable" id="table2">
	      <property name="border_width">10</property>
	      <property name="visible">True</property>
	      <property name="n_rows">2</property>
	      <property name="n_columns">2</property>
	      <property name="homogeneous">False</property>
	      <property name="row_spacing">2</property>
	      <property name="column_spacing">2</property>

	      <child>
		<widget class="GtkFontButton" id="font_gear_title">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="show_style">True</property>
		  <property name="show_size">True</property>
		  <property name="use_font">True</property>
		  <property name="use_size">True</property>
		  <property name="focus_on_click">True</property>
		</widget>
		<packing>
		  <property name="left_attach">1</property>
		  <property name="right_attach">2</property>
		  <property name="top_attach">0</property>
		  <property name="bottom_attach">1</property>
		  <property name="x_options">fill</property>
		  <property name="y_options"></property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkLabel" id="label6">
		  <property name="visible">True</property>
		  <property name="label" translatable="yes">Gear title font</property>
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
		  <property name="y_options"></property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkFontButton" id="font_text_window">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="show_style">True</property>
		  <property name="show_size">True</property>
		  <property name="use_font">True</property>
		  <property name="use_size">True</property>
		  <property name="focus_on_click">True</property>
		</widget>
		<packing>
		  <property name="left_attach">1</property>
		  <property name="right_attach">2</property>
		  <property name="top_attach">1</property>
		  <property name="bottom_attach">2</property>
		  <property name="x_options">fill</property>
		  <property name="y_options"></property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkLabel" id="label8">
		  <property name="visible">True</property>
		  <property name="label" translatable="yes">Text window font</property>
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
		  <property name="top_attach">1</property>
		  <property name="bottom_attach">2</property>
		  <property name="x_options">fill</property>
		  <property name="y_options"></property>
		</packing>
	      </child>
	    </widget>
	    <packing>
	      <property name="tab_expand">False</property>
	      <property name="tab_fill">True</property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="label5">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Fonts</property>
	      <property name="use_underline">False</property>
	      <property name="use_markup">False</property>
	      <property name="justify">GTK_JUSTIFY_LEFT</property>
	      <property name="wrap">False</property>
	      <property name="selectable">False</property>
	      <property name="xalign">0.5</property>
	      <property name="yalign">0.5</property>
	      <property name="xpad">0</property>
	      <property name="ypad">0</property>
	    </widget>
	    <packing>
	      <property name="type">tab</property>
	    </packing>
	  </child>
	</widget>
	<packing>
	  <property name="padding">5</property>
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

