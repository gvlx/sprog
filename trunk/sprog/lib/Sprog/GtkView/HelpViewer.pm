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
  app helpwin textview buffer statusbar hovering
));

use Scalar::Util qw(weaken);

use constant HOME_TOPIC => 'Sprog::help::index';


my $cursor     = Gtk2::Gdk::Cursor->new('xterm');
my $url_cursor = Gtk2::Gdk::Cursor->new('hand2');


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
  my $font_desc = Gtk2::Pango::FontDescription->from_string("Serif 10");
  $textview->modify_font($font_desc);
  $textview->set_wrap_mode('word');
  $textview->set_left_margin(6);
  $textview->set_right_margin(4);

  $textview->get_window('text')->set_events([qw(
    exposure-mask
    pointer-motion-mask
    button-press-mask
    button-release-mask
    key-press-mask
    structure-mask
    property-change-mask
    scroll-mask
  )]);

  $textview->signal_connect(
    'motion_notify_event' => sub { $self->on_motion_notify_event(@_); }
  );

  $textview->signal_connect(
    'button_release_event' => sub { $self->on_clicked(@_); }
  );

  my $buffer = $self->buffer($self->textview->get_buffer);

  $self->statusbar($gladexml->get_widget('statusbar'));

  $self->_init_tags($buffer, $font_desc->get_size);

  return $self;
}


sub _init_tags {
  my($self, $buffer, $size) = @_;

  my %tag_data = (
    head1 =>      {
                    family             => 'Sans',
                    weight             => PANGO_WEIGHT_BOLD,
                    size               => $size * 1.6,
                    pixels_above_lines => 12,
                    pixels_below_lines => 4,
                  },

    head2 =>      {
                    family             => 'Sans',
                    weight             => PANGO_WEIGHT_BOLD,
                    size               => $size * 1.4,
                    pixels_above_lines => 4,
                    pixels_below_lines => 2,
                  },

    head3 =>      {
                    family             => 'Sans',
                    weight             => PANGO_WEIGHT_BOLD,
                    size               => $size * 1.2,
                    pixels_above_lines => 6,
                    pixels_below_lines => 2,
                  },

    head4 =>      {
                    family             => 'Sans',
                    weight             => PANGO_WEIGHT_BOLD,
                    size               => $size,
                    pixels_above_lines => 6,
                    pixels_below_lines => 2,
                  },

    para =>       {
                    pixels_below_lines => 8,
                  },

    bullet =>     {
                    left_margin        => 20,
                    pixels_above_lines => 2,
                    pixels_below_lines => 2,
                  },

    verbatim =>   {
                    wrap_mode          => 'none',
                    family             => 'monospace',
                    size               => $size,
                  },

    bold =>       {
                    weight             => PANGO_WEIGHT_BOLD,
                  },

    italic =>     {
                    style              => 'italic'
                  },

    code =>       {
                    family             => 'monospace',
                  },

    link =>       {
                    foreground         => 'blue',
                  }
  );

  while(my($name, $data) = each %tag_data) {
    $self->{tag}->{$name} = $buffer->create_tag($name, %$data);
  }

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
  $self->status_message('');

  my $file = $self->_find_file($topic);
  if($file) {
    my $parser = $self->app->factory->make_class('/app/help_parser', $self);
    $parser->parse_file($file);
    return if $parser->content_seen;
  }
  $self->add_tagged_text("Unable to find help for topic '$topic'", ['head3']);
}


sub clear {
  my $self = shift;

  $self->buffer->set_text('');
  my $tag_table = $self->buffer->get_tag_table;
  $tag_table->foreach(sub { $tag_table->remove($_[0]) if $_[0]->{link_type}; });
}


sub link_data {
  my $self = shift;

  $self->{link_type}   = shift;
  $self->{link_target} = shift;
}


sub add_tagged_text {
  my($self, $text, $tag_names) = @_;

  my @tags = map { $self->{tag}->{$_} ? $self->{tag}->{$_} : () } @$tag_names;

  my $buffer = $self->buffer;

  if(grep($_ eq 'link', @$tag_names)) {
    if($self->{link_type}) {
      my $tag = $buffer->create_tag(undef, underline => 'single');
      $tag->{link_type}   = delete $self->{link_type};
      $tag->{link_target} = delete $self->{link_target};
      push @tags, $tag;
    }
  }

  my $iter = $buffer->get_end_iter;
  $buffer->insert_with_tags($iter, $text, @tags);
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


sub on_enter_link {
  my $self = shift;

  my $link = $self->hovering or return;
  $self->status_message($link->{link_target});
  $self->textview->get_window('text')->set_cursor($url_cursor);
}


sub on_exit_link {
  my $self = shift;

  $self->status_message('');
  $self->textview->get_window('text')->set_cursor($cursor);
}


sub on_clicked {
  my($self, $event) = @_;

  my $link = $self->hovering or return FALSE;

  if($link->{link_type} ne 'pod') {
    $self->status_message("'$link->{link_type}' links not implemented");
    return FALSE;
  }
  
  $self->app->add_idle_handler(
    sub { $self->set_topic($link->{link_target}); return FALSE; }
  );

  return FALSE;
}


sub on_motion_notify_event {
  my($self, $textview, $event) = @_;

  return FALSE if $self->buffer->get_selection_bounds;

  my($x, $y) = $textview->window_to_buffer_coords('text', $event->x, $event->y);
  my $link_tag = $self->{tag}->{link};
  my $iter  = $textview->get_iter_at_location($x, $y);
  my $hover = $iter->has_tag($link_tag);
  if($hover and !$self->hovering) {
    my($tag) = grep { exists $_->{link_type} } $iter->get_tags;
    $self->hovering({
      link_type   => $tag->{link_type},
      link_target => $tag->{link_target},
    });
    $self->on_enter_link;
  }
  elsif(!$hover and $self->hovering) {
    $self->hovering(undef);
    $self->on_exit_link;
  }

  return FALSE;
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

