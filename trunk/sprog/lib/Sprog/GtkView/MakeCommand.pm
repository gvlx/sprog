package Sprog::GtkView::MakeCommand;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2::GladeXML;

use base qw(
  Sprog::Accessor
);

__PACKAGE__->mk_accessors(qw(
  app
  chrome
  dialog
  gear_dir
  gear
  types
  title
  command
  keywords
  filename
  custom_filename
));

use Scalar::Util qw(weaken);

use constant HELP_TOPIC => 'Sprog::help::make_command';


sub invoke {
  my($class, $app, $gear_dir, $gear) = @_;

  my $self = $class->new(
    app      => $app, 
    chrome   => $app->view->chrome_class,
    gear_dir => $gear_dir, 
    gear     => $gear
  );

  my $dialog = $self->dialog or return;

  while(my $resp = $dialog->run) {
    if($resp eq 'help') {
#      my $topic = $self->gearview->gear_class;
#      $self->app->show_help(HELP_TOPIC);
      next;
    }
    if($resp eq 'ok') {
      next unless $self->save;
    }
    last;
  }

  $dialog->destroy;
}


sub new { 
  my $class = shift;

  my $self = bless({ @_, custom_filename => 0 }, $class);
  weaken($self->{app});

  return $self->_init;
}


sub _init {
  my $self = shift;

  my $glade_src = $self->glade_xml;
  my $gladexml = Gtk2::GladeXML->new_from_buffer($glade_src);

  $self->dialog($gladexml->get_widget('make_command'));

  my $app  = $self->app;
  my $view = $app->view;

  $gladexml->get_widget('image_input')->set_from_pixbuf(
    $self->_gear_icon('_', 'P')
  );
  $gladexml->get_widget('image_filter')->set_from_pixbuf(
    $self->_gear_icon('P', 'P')
  );
  $gladexml->get_widget('image_output')->set_from_pixbuf(
    $self->_gear_icon('P', '_')
  );

  $self->types($gladexml->get_widget('gear_type_input')->get_group);
  $self->title($gladexml->get_widget('title'));
  $self->command($gladexml->get_widget('command'));
  $self->keywords($gladexml->get_widget('keywords'));
  $self->filename($gladexml->get_widget('filename'));

  $gladexml->signal_autoconnect_from_package($self);

  return $self;
}


sub _gear_icon {
  my $self = shift;

  return $self->chrome->mini_gear_icon(@_);
}


sub on_title_changed {
  my($self, $widget) = @_;

  my $filename = $self->filename or return;
  my $text = $filename->get_text;
  $self->custom_filename(0) if $text eq $self->_default_filename;

  return if $self->custom_filename;

  $filename->set_text($self->_default_filename);
}


sub on_filename_changed {
  my($self, $widget) = @_;

  my $text = $widget->get_text;
  return $self->custom_filename(1) if $text ne $self->_default_filename;

  $self->custom_filename(0);
}


sub _default_filename {
  my $self = shift;

  my $title = $self->title->get_text or return '';
  $title =~ s/[\W_]+/ /g;

  return join('', map { ucfirst lc $_ } split /\s+/, $title) . '.pm';
}


sub save {
  my($self) = @_;

  my $app  = $self->app;
  my $gear = { type => 'input' };

  foreach my $rb (@{ $self->types }) {
    next unless $rb->get_active;
    next unless $rb->get_name =~ /^gear_type_(\w+)/;
    $gear->{type} = $1;
    last;
  };

  $gear->{title}   = $self->title->get_text;
  return $app->alert("You must enter a title") unless length($gear->{title});

  $gear->{command} = $self->command->get_text;
  return $app->alert("You must enter a command") unless length($gear->{command});

  $gear->{keywords} = $self->keywords->get_text;

  $gear->{class} = $self->filename->get_text;
  $gear->{class} =~ s{\.pm?$}{};
  $gear->{class} =~ s{[\W_]}{}g;
  return $app->alert("You must enter a filename") unless length($gear->{class});

  return $self->_write_gear_to_file($gear);
}


sub _write_gear_to_file {
  my($self, $gear) = @_;

  my $app  = $self->app;
  my $dir  = $self->gear_dir;
  my $path = File::Spec->catfile($dir, $gear->{class} . '.pm');

  return if -e $path
            && !$app->confirm_yes_no('Save As', 'File exists.  Overwrite?');

  if($gear->{type} eq 'input') {
    $gear->{conn_in}  = '_';
    $gear->{conn_out} = 'P';
    $gear->{parent}   = 'CommandIn';
  }
  elsif($gear->{type} eq 'filter') {
    $gear->{conn_in}  = 'P';
    $gear->{conn_out} = 'P';
    $gear->{parent}   = 'FilterCommand';
  }
  else {
    $gear->{conn_in}  = 'P';
    $gear->{conn_out} = '_';
    $gear->{parent}   = 'CommandOut';
  }

  $gear->{command} =~ s{([()])}{\\$1}g;

  open my $fh, '>', $path or return $self->app->alert(
    "Error creating $path", "$!"
  );

  print $fh <<"EOF";
package $gear->{class};

=begin sprog-gear-metadata

  title: $gear->{title}
  type_in: $gear->{conn_in}
  type_out: $gear->{conn_out}
  keywords: $gear->{keywords}
  no_properties: 1

=end sprog-gear-metadata

=cut

use strict;

use base qw(Sprog::Gear::$gear->{parent});

__PACKAGE__->declare_properties( -command => undef );

sub command { q($gear->{command}); }

1;
EOF

  close($fh);
  
  $app->init_private_path;  # refresh palette view

  return 1;
}


sub glade_xml {
  return `cat /home/grant/projects/sf/sprog/glade/make_command.glade`;
  return <<'END_XML';
<?xml version="1.0" standalone="no"?> <!--*- mode: xml -*-->
<!DOCTYPE glade-interface SYSTEM "http://glade.gnome.org/glade-2.0.dtd">

<glade-interface>

<widget class="GtkDialog" id="make_command">
  <property name="visible">True</property>
  <property name="title" translatable="yes">Create Command Gear</property>
  <property name="type">GTK_WINDOW_TOPLEVEL</property>
  <property name="window_position">GTK_WIN_POS_MOUSE</property>
  <property name="modal">False</property>
  <property name="default_width">380</property>
  <property name="resizable">True</property>
  <property name="destroy_with_parent">False</property>
  <property name="decorated">True</property>
  <property name="skip_taskbar_hint">False</property>
  <property name="skip_pager_hint">False</property>
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
	    <widget class="GtkButton" id="helpbutton1">
	      <property name="visible">True</property>
	      <property name="can_default">True</property>
	      <property name="can_focus">True</property>
	      <property name="label">gtk-help</property>
	      <property name="use_stock">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <property name="focus_on_click">True</property>
	      <property name="response_id">-11</property>
	    </widget>
	  </child>

	  <child>
	    <widget class="GtkButton" id="cancel">
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
	    <widget class="GtkButton" id="save">
	      <property name="visible">True</property>
	      <property name="can_default">True</property>
	      <property name="has_default">True</property>
	      <property name="can_focus">True</property>
	      <property name="label">gtk-save</property>
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
	<widget class="GtkTable" id="table1">
	  <property name="border_width">6</property>
	  <property name="visible">True</property>
	  <property name="n_rows">10</property>
	  <property name="n_columns">1</property>
	  <property name="homogeneous">False</property>
	  <property name="row_spacing">5</property>
	  <property name="column_spacing">5</property>

	  <child>
	    <widget class="GtkLabel" id="label1">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Gear Type:</property>
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
	    <widget class="GtkLabel" id="label2">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Gear Title:</property>
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
	      <property name="top_attach">2</property>
	      <property name="bottom_attach">3</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="label3">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Command:</property>
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
	      <property name="top_attach">4</property>
	      <property name="bottom_attach">5</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkEntry" id="title">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="editable">True</property>
	      <property name="visibility">True</property>
	      <property name="max_length">0</property>
	      <property name="text" translatable="yes"></property>
	      <property name="has_frame">True</property>
	      <property name="invisible_char">*</property>
	      <property name="activates_default">False</property>
	      <signal name="changed" handler="on_title_changed" last_modification_time="Thu, 30 Jun 2005 11:32:22 GMT"/>
	    </widget>
	    <packing>
	      <property name="left_attach">0</property>
	      <property name="right_attach">1</property>
	      <property name="top_attach">3</property>
	      <property name="bottom_attach">4</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkEntry" id="command">
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
	      <property name="left_attach">0</property>
	      <property name="right_attach">1</property>
	      <property name="top_attach">5</property>
	      <property name="bottom_attach">6</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkVBox" id="vbox1">
	      <property name="visible">True</property>
	      <property name="homogeneous">False</property>
	      <property name="spacing">0</property>

	      <child>
		<widget class="GtkRadioButton" id="gear_type_input">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="has_focus">True</property>
		  <property name="relief">GTK_RELIEF_NORMAL</property>
		  <property name="focus_on_click">True</property>
		  <property name="active">False</property>
		  <property name="inconsistent">False</property>
		  <property name="draw_indicator">True</property>

		  <child>
		    <widget class="GtkAlignment" id="alignment1">
		      <property name="visible">True</property>
		      <property name="xalign">0.5</property>
		      <property name="yalign">0.5</property>
		      <property name="xscale">0</property>
		      <property name="yscale">0</property>
		      <property name="top_padding">0</property>
		      <property name="bottom_padding">0</property>
		      <property name="left_padding">0</property>
		      <property name="right_padding">0</property>

		      <child>
			<widget class="GtkHBox" id="hbox1">
			  <property name="visible">True</property>
			  <property name="homogeneous">False</property>
			  <property name="spacing">2</property>

			  <child>
			    <widget class="GtkImage" id="image_input">
			      <property name="visible">True</property>
			      <property name="stock">gtk-connect</property>
			      <property name="icon_size">4</property>
			      <property name="xalign">0.5</property>
			      <property name="yalign">0.5</property>
			      <property name="xpad">0</property>
			      <property name="ypad">0</property>
			    </widget>
			    <packing>
			      <property name="padding">0</property>
			      <property name="expand">False</property>
			      <property name="fill">False</property>
			    </packing>
			  </child>

			  <child>
			    <widget class="GtkLabel" id="label4">
			      <property name="visible">True</property>
			      <property name="label" translatable="yes">Input gear</property>
			      <property name="use_underline">True</property>
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
			      <property name="padding">0</property>
			      <property name="expand">False</property>
			      <property name="fill">False</property>
			    </packing>
			  </child>
			</widget>
		      </child>
		    </widget>
		  </child>
		</widget>
		<packing>
		  <property name="padding">0</property>
		  <property name="expand">False</property>
		  <property name="fill">False</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkRadioButton" id="gear_type_filter">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="relief">GTK_RELIEF_NORMAL</property>
		  <property name="focus_on_click">True</property>
		  <property name="active">False</property>
		  <property name="inconsistent">False</property>
		  <property name="draw_indicator">True</property>
		  <property name="group">gear_type_input</property>

		  <child>
		    <widget class="GtkAlignment" id="alignment2">
		      <property name="visible">True</property>
		      <property name="xalign">0.5</property>
		      <property name="yalign">0.5</property>
		      <property name="xscale">0</property>
		      <property name="yscale">0</property>
		      <property name="top_padding">0</property>
		      <property name="bottom_padding">0</property>
		      <property name="left_padding">0</property>
		      <property name="right_padding">0</property>

		      <child>
			<widget class="GtkHBox" id="hbox2">
			  <property name="visible">True</property>
			  <property name="homogeneous">False</property>
			  <property name="spacing">2</property>

			  <child>
			    <widget class="GtkImage" id="image_filter">
			      <property name="visible">True</property>
			      <property name="stock">gtk-connect</property>
			      <property name="icon_size">4</property>
			      <property name="xalign">0.5</property>
			      <property name="yalign">0.5</property>
			      <property name="xpad">0</property>
			      <property name="ypad">0</property>
			    </widget>
			    <packing>
			      <property name="padding">0</property>
			      <property name="expand">False</property>
			      <property name="fill">False</property>
			    </packing>
			  </child>

			  <child>
			    <widget class="GtkLabel" id="label5">
			      <property name="visible">True</property>
			      <property name="label" translatable="yes">Filter gear</property>
			      <property name="use_underline">True</property>
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
			      <property name="padding">0</property>
			      <property name="expand">False</property>
			      <property name="fill">False</property>
			    </packing>
			  </child>
			</widget>
		      </child>
		    </widget>
		  </child>
		</widget>
		<packing>
		  <property name="padding">0</property>
		  <property name="expand">False</property>
		  <property name="fill">False</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkRadioButton" id="gear_type_output">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="relief">GTK_RELIEF_NORMAL</property>
		  <property name="focus_on_click">True</property>
		  <property name="active">False</property>
		  <property name="inconsistent">False</property>
		  <property name="draw_indicator">True</property>
		  <property name="group">gear_type_input</property>

		  <child>
		    <widget class="GtkAlignment" id="alignment3">
		      <property name="visible">True</property>
		      <property name="xalign">0.5</property>
		      <property name="yalign">0.5</property>
		      <property name="xscale">0</property>
		      <property name="yscale">0</property>
		      <property name="top_padding">0</property>
		      <property name="bottom_padding">0</property>
		      <property name="left_padding">0</property>
		      <property name="right_padding">0</property>

		      <child>
			<widget class="GtkHBox" id="hbox3">
			  <property name="visible">True</property>
			  <property name="homogeneous">False</property>
			  <property name="spacing">2</property>

			  <child>
			    <widget class="GtkImage" id="image_output">
			      <property name="visible">True</property>
			      <property name="stock">gtk-connect</property>
			      <property name="icon_size">4</property>
			      <property name="xalign">0.5</property>
			      <property name="yalign">0.5</property>
			      <property name="xpad">0</property>
			      <property name="ypad">0</property>
			    </widget>
			    <packing>
			      <property name="padding">0</property>
			      <property name="expand">False</property>
			      <property name="fill">False</property>
			    </packing>
			  </child>

			  <child>
			    <widget class="GtkLabel" id="label6">
			      <property name="visible">True</property>
			      <property name="label" translatable="yes">Output gear</property>
			      <property name="use_underline">True</property>
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
			      <property name="padding">0</property>
			      <property name="expand">False</property>
			      <property name="fill">False</property>
			    </packing>
			  </child>
			</widget>
		      </child>
		    </widget>
		  </child>
		</widget>
		<packing>
		  <property name="padding">0</property>
		  <property name="expand">False</property>
		  <property name="fill">False</property>
		</packing>
	      </child>
	    </widget>
	    <packing>
	      <property name="left_attach">0</property>
	      <property name="right_attach">1</property>
	      <property name="top_attach">1</property>
	      <property name="bottom_attach">2</property>
	      <property name="x_padding">10</property>
	      <property name="x_options">fill</property>
	      <property name="y_options">fill</property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="label7">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Keywords:</property>
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
	      <property name="top_attach">6</property>
	      <property name="bottom_attach">7</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkEntry" id="keywords">
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
	      <property name="left_attach">0</property>
	      <property name="right_attach">1</property>
	      <property name="top_attach">7</property>
	      <property name="bottom_attach">8</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="label8">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">File name:</property>
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
	      <property name="top_attach">8</property>
	      <property name="bottom_attach">9</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkEntry" id="filename">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="editable">True</property>
	      <property name="visibility">True</property>
	      <property name="max_length">0</property>
	      <property name="text" translatable="yes"></property>
	      <property name="has_frame">True</property>
	      <property name="invisible_char">*</property>
	      <property name="activates_default">False</property>
	      <signal name="changed" handler="on_filename_changed" last_modification_time="Thu, 30 Jun 2005 11:32:43 GMT"/>
	    </widget>
	    <packing>
	      <property name="left_attach">0</property>
	      <property name="right_attach">1</property>
	      <property name="top_attach">9</property>
	      <property name="bottom_attach">10</property>
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

