package Sprog::GtkView::HelpViewer;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2::GladeXML;
use Gtk2::Pango;
use File::Spec;

use base qw(
  Class::Accessor::Fast
);

__PACKAGE__->mk_accessors(qw(
  app helpwin textview buffer statusbar
));

use Scalar::Util qw(weaken);

use constant HOME_TOPIC => 'Sprog::help::index';


sub show_help {
  my($class, $app, $topic) = @_;

  my $self = $class->new(app => $app);

  $self->set_topic($topic);
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

  $gladexml->signal_autoconnect(
    sub { $self->autoconnect(@_) }
  );

  my $window = $self->helpwin($gladexml->get_widget('helpwin'));
  $window->resize(600, 580);

  my $textview = $self->textview($gladexml->get_widget('textview'));
  $textview->set_editable(FALSE);
  $textview->set_cursor_visible(FALSE);
  my $font_desc = Gtk2::Pango::FontDescription->from_string ("Serif 10");
  $textview->modify_font ($font_desc);
  $textview->set_wrap_mode('word');
  $textview->set_left_margin(6);
  $textview->set_right_margin(4);

  my $buffer = $self->buffer($self->textview->get_buffer);

  $self->statusbar($gladexml->get_widget('statusbar'));

  $self->_init_tags($buffer, $font_desc->get_size);

  return $self;
}


sub _init_tags {
  my($self, $buffer, $size) = @_;

  $buffer->create_tag('head1',
    family             => 'Sans',
    weight             => PANGO_WEIGHT_BOLD,
    size               => $size * 1.6,
    pixels_above_lines => 12,
    pixels_below_lines => 4,
  );

  $buffer->create_tag('head2',
    family             => 'Sans',
    weight             => PANGO_WEIGHT_BOLD,
    size               => $size * 1.4,
    pixels_above_lines => 4,
    pixels_below_lines => 2,
  );

  $buffer->create_tag('head3',
    family             => 'Sans',
    weight             => PANGO_WEIGHT_BOLD,
    size               => $size * 1.2,
    pixels_above_lines => 6,
    pixels_below_lines => 2,
  );

  $buffer->create_tag('head4',
    family             => 'Sans',
    weight             => PANGO_WEIGHT_BOLD,
    size               => $size,
    pixels_above_lines => 6,
    pixels_below_lines => 2,
  );

  $buffer->create_tag('para',
    pixels_below_lines => 8,
  );

  $buffer->create_tag('bullet',
    left_margin        => 20,
    pixels_above_lines => 2,
    pixels_below_lines => 2,
  );

  $buffer->create_tag('verbatim',
    wrap_mode          => 'none',
    family             => 'monospace',
    size               => $size,
  );

  $buffer->create_tag('bold',
    weight             => PANGO_WEIGHT_BOLD,
  );

  $buffer->create_tag('italic',
    style              => 'italic'
  );

  $buffer->create_tag('code',
    family             => 'monospace',
  );

  $buffer->create_tag('link',
    underline          => 'single',
    foreground         => 'blue',
  );

}


sub autoconnect {
  my($self, $method, $widget, $signal) = @_;

  die __PACKAGE__ . " has no $method method"
    unless $self->can($method);
    
  $widget->signal_connect(
    $signal => sub { $self->$method(@_) }
  );
}


sub set_topic {
  my($self, $topic) = @_;

  $self->clear;

  my $file = $self->_find_file($topic);
  if($file) {
    my $parser = $self->app->factory->make_class('/app/help_parser', $self);
    $parser->parse_file($file);
    return if $parser->content_seen;
  }
  $self->add_tagged_text("Unable to find help for topic '$topic'", 'head3');
}


sub clear {
  my $self = shift;

  $self->buffer->set_text('');
}


sub add_tagged_text {
  my($self, $text, $tags) = @_;

  my $buffer = $self->buffer;
  my $iter   = $buffer->get_end_iter;
  $buffer->insert_with_tags_by_name($iter, $text, @$tags);
}


sub _find_file {
  my($self, $topic) = @_;

  my @parts = split /::/, $topic;

  foreach my $dir (@INC) {
    my $path = File::Spec->catfile($dir, @parts);
    return "$path.pod" if -r "$path.pod";
    return "$path.pm"  if -r "$path.pm";
  }

  return;
}


sub status_message {
  my($self, $message) = @_;

  my $statusbar = $self->statusbar;
  $statusbar->pop(0);
  $statusbar->push(0, $message);
}


########################### GUI Event Handlers ###############################

sub on_close_activated {
  my $self = shift;

  $self->helpwin->destroy;
}


sub on_find_activated {
  my $self = shift;

  $self->status_message('Find not implemented');
}


sub on_back_activated {
  my $self = shift;

  $self->status_message('Back not implemented');
}


sub on_forward_activated {
  my $self = shift;

  $self->status_message('Forward not implemented');
}


sub on_home_activated {
  my $self = shift;

  $self->set_topic(HOME_TOPIC);
}


sub glade_xml {

  return <<'END_XML';
<?xml version="1.0" standalone="no"?> <!--*- mode: xml -*-->
<!DOCTYPE glade-interface SYSTEM "http://glade.gnome.org/glade-2.0.dtd">

<glade-interface>

<widget class="GtkWindow" id="helpwin">
  <property name="visible">True</property>
  <property name="title" translatable="yes">Sprog Help</property>
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
	<widget class="GtkMenuBar" id="menubar1">
	  <property name="visible">True</property>

	  <child>
	    <widget class="GtkMenuItem" id="menuitem3">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">_File</property>
	      <property name="use_underline">True</property>

	      <child>
		<widget class="GtkMenu" id="menuitem3_menu">

		  <child>
		    <widget class="GtkImageMenuItem" id="close">
		      <property name="visible">True</property>
		      <property name="label">gtk-close</property>
		      <property name="use_stock">True</property>
		      <signal name="activate" handler="on_close_activated" last_modification_time="Wed, 23 Mar 2005 08:01:01 GMT"/>
		    </widget>
		  </child>
		</widget>
	      </child>
	    </widget>
	  </child>

	  <child>
	    <widget class="GtkMenuItem" id="menuitem4">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">_Edit</property>
	      <property name="use_underline">True</property>

	      <child>
		<widget class="GtkMenu" id="menuitem4_menu">

		  <child>
		    <widget class="GtkImageMenuItem" id="find">
		      <property name="visible">True</property>
		      <property name="label">gtk-find</property>
		      <property name="use_stock">True</property>
		      <signal name="activate" handler="on_find_activated" last_modification_time="Wed, 23 Mar 2005 08:01:01 GMT"/>
		    </widget>
		  </child>
		</widget>
	      </child>
	    </widget>
	  </child>

	  <child>
	    <widget class="GtkMenuItem" id="menuitem3">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">_Go</property>
	      <property name="use_underline">True</property>

	      <child>
		<widget class="GtkMenu" id="menuitem3_menu">

		  <child>
		    <widget class="GtkImageMenuItem" id="back_menuitem">
		      <property name="visible">True</property>
		      <property name="label">gtk-go-back</property>
		      <property name="use_stock">True</property>
		      <signal name="activate" handler="on_back_activated" last_modification_time="Wed, 23 Mar 2005 08:01:01 GMT"/>
		    </widget>
		  </child>

		  <child>
		    <widget class="GtkImageMenuItem" id="forward_menuitem">
		      <property name="visible">True</property>
		      <property name="label">gtk-go-forward</property>
		      <property name="use_stock">True</property>
		      <signal name="activate" handler="on_forward_activated" last_modification_time="Wed, 23 Mar 2005 08:01:01 GMT"/>
		    </widget>
		  </child>

		  <child>
		    <widget class="GtkSeparatorMenuItem" id="separator1">
		      <property name="visible">True</property>
		    </widget>
		  </child>

		  <child>
		    <widget class="GtkImageMenuItem" id="home_menuitem">
		      <property name="visible">True</property>
		      <property name="label">gtk-home</property>
		      <property name="use_stock">True</property>
		      <signal name="activate" handler="on_home_activated" last_modification_time="Wed, 23 Mar 2005 08:01:01 GMT"/>
		    </widget>
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
	<widget class="GtkToolbar" id="toolbar1">
	  <property name="visible">True</property>
	  <property name="orientation">GTK_ORIENTATION_HORIZONTAL</property>
	  <property name="toolbar_style">GTK_TOOLBAR_BOTH</property>
	  <property name="tooltips">True</property>
	  <property name="show_arrow">True</property>

	  <child>
	    <widget class="GtkToolButton" id="back_button">
	      <property name="visible">True</property>
	      <property name="stock_id">gtk-go-back</property>
	      <property name="visible_horizontal">True</property>
	      <property name="visible_vertical">True</property>
	      <property name="is_important">False</property>
	      <signal name="clicked" handler="on_back_activated" last_modification_time="Tue, 22 Mar 2005 18:27:30 GMT"/>
	    </widget>
	    <packing>
	      <property name="expand">False</property>
	      <property name="homogeneous">True</property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkToolButton" id="forward_button">
	      <property name="visible">True</property>
	      <property name="stock_id">gtk-go-forward</property>
	      <property name="visible_horizontal">True</property>
	      <property name="visible_vertical">True</property>
	      <property name="is_important">False</property>
	      <signal name="clicked" handler="on_forward_activated" last_modification_time="Tue, 22 Mar 2005 18:27:44 GMT"/>
	    </widget>
	    <packing>
	      <property name="expand">False</property>
	      <property name="homogeneous">True</property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkSeparatorToolItem" id="separatortoolitem1">
	      <property name="visible">True</property>
	      <property name="draw">True</property>
	      <property name="visible_horizontal">True</property>
	      <property name="visible_vertical">True</property>
	    </widget>
	    <packing>
	      <property name="expand">False</property>
	      <property name="homogeneous">False</property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkToolButton" id="home_button">
	      <property name="visible">True</property>
	      <property name="stock_id">gtk-home</property>
	      <property name="visible_horizontal">True</property>
	      <property name="visible_vertical">True</property>
	      <property name="is_important">False</property>
	      <signal name="clicked" handler="on_home_activated" last_modification_time="Tue, 22 Mar 2005 18:28:06 GMT"/>
	    </widget>
	    <packing>
	      <property name="expand">False</property>
	      <property name="homogeneous">True</property>
	    </packing>
	  </child>
	</widget>
	<packing>
	  <property name="padding">0</property>
	  <property name="expand">False</property>
	  <property name="fill">False</property>
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
	    <widget class="GtkTextView" id="textview">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="editable">True</property>
	      <property name="overwrite">False</property>
	      <property name="accepts_tab">True</property>
	      <property name="justification">GTK_JUSTIFY_LEFT</property>
	      <property name="wrap_mode">GTK_WRAP_NONE</property>
	      <property name="cursor_visible">True</property>
	      <property name="pixels_above_lines">0</property>
	      <property name="pixels_below_lines">0</property>
	      <property name="pixels_inside_wrap">0</property>
	      <property name="left_margin">0</property>
	      <property name="right_margin">0</property>
	      <property name="indent">0</property>
	      <property name="text" translatable="yes"></property>
	    </widget>
	  </child>
	</widget>
	<packing>
	  <property name="padding">0</property>
	  <property name="expand">True</property>
	  <property name="fill">True</property>
	</packing>
      </child>

      <child>
	<widget class="GtkStatusbar" id="statusbar">
	  <property name="visible">True</property>
	  <property name="has_resize_grip">True</property>
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

</glade-interface>
END_XML

}

1;

