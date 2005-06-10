package Sprog::GtkView::HelpViewer;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2::GladeXML;
use Gtk2::Pango;

use base qw(
  Sprog::Accessor
);

__PACKAGE__->mk_accessors(qw(
  app helpwin textview buffer menubar statusbar
  back_button forward_button home_button
  back_menuitem forward_menuitem home_menuitem
  hovering
  trail trail_index
));

use Scalar::Util qw(weaken);

use constant HOME_TOPIC => 'Sprog::help::index';

use constant DEFAULT_WIDTH  => 600;
use constant DEFAULT_HEIGHT => 580;


my $cursor     = Gtk2::Gdk::Cursor->new('xterm');
my $url_cursor = Gtk2::Gdk::Cursor->new('hand2');


sub show_help {
  my($class, $app, $topic) = @_;

  my $self = $class->new(app => $app);

  $self->go_to_topic($topic);
}


sub new { 
  my $class = shift;

  my $self = bless({ @_ }, $class);
  weaken($self->{app});

  return $self->_init;
}


sub _init {
  my $self = shift;

  $self->trail([]);
  $self->trail_index(undef);

  my $glade_src = $self->glade_xml;
  my $width  = $self->app->get_pref('help_win.width')  || DEFAULT_WIDTH;
  my $height = $self->app->get_pref('help_win.height') || DEFAULT_HEIGHT;
  $glade_src =~ s/<% default_width %>/$width/;
  $glade_src =~ s/<% default_height %>/$height/;

  my $gladexml = Gtk2::GladeXML->new_from_buffer($glade_src);

  $gladexml->signal_autoconnect(
    sub { $self->autoconnect(@_) }
  );

  my $window = $self->helpwin($gladexml->get_widget('helpwin'));

  my $textview = $self->textview($gladexml->get_widget('textview'));
  $textview->set_editable(FALSE);
  $textview->set_cursor_visible(FALSE);
  my $font_desc = Gtk2::Pango::FontDescription->from_string("Serif 10");
  $textview->modify_font($font_desc);
  $textview->set_wrap_mode('word');
  $textview->set_left_margin(16);
  $textview->set_right_margin(12);

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

  $self->menubar($gladexml->get_widget('menubar'));
  $self->statusbar($gladexml->get_widget('statusbar'));

  $self->back_button($gladexml->get_widget('back_button'));
  $self->forward_button($gladexml->get_widget('forward_button'));
  $self->home_button($gladexml->get_widget('home_button'));

  $self->back_menuitem($gladexml->get_widget('back_menuitem'));
  $self->forward_menuitem($gladexml->get_widget('forward_menuitem'));
  $self->home_menuitem($gladexml->get_widget('home_menuitem'));

  $self->_init_tags($buffer, $font_desc->get_size);

  $window->signal_connect(
    size_allocate => sub { $self->on_size_allocate(@_); }
  );

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
                    pixels_above_lines => 10,
                    pixels_below_lines => 2,
                  },

    head3 =>      {
                    family             => 'Sans',
                    weight             => PANGO_WEIGHT_BOLD,
                    size               => $size * 1.2,
                    pixels_above_lines => 8,
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
                    pixels_above_lines => 6,
                    pixels_below_lines => 6,
                  },

    bullet =>     {
                    pixels_above_lines => 1,
                    pixels_below_lines => 9,
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
                  },

    indent1 =>    { left_margin        => 10 + 20 * 1, },
    indent2 =>    { left_margin        => 10 + 20 * 2, },
    indent3 =>    { left_margin        => 10 + 20 * 3, },
    indent4 =>    { left_margin        => 10 + 20 * 4, },
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


sub go_to_topic {
  my($self, $topic) = @_;

  my $trail = $self->trail;

  if(@$trail) {
    my $i = $self->trail_index;
    if($i < $#{$trail}) {
      splice @$trail, $i+1;
    }
    $self->save_scroll_pos;
  }

  push @$trail, [ $topic, 0 ];
  $self->trail_index($#{$trail});

  $self->load_topic;
}


sub save_scroll_pos {
  my $self = shift;

  my $trail = $self->trail;
  return unless @$trail;

  my $pos = $self->textview->parent->get_vadjustment->get_value;
  $trail->[$self->trail_index]->[1] = $pos;
}


sub can_back {
  my $self = shift;

  my $trail = $self->trail;
  return FALSE unless @$trail;

  my $i = $self->trail_index;
  return FALSE unless $i > 0;

  return TRUE;
}


sub go_back {
  my $self = shift;

  return unless $self->can_back;

  $self->save_scroll_pos;
  $self->trail_index($self->trail_index - 1);
  $self->load_topic;
}


sub can_forward {
  my $self = shift;

  my $trail = $self->trail;
  return FALSE unless @$trail;

  my $i = $self->trail_index;
  return FALSE unless $i < $#{$trail};

  return TRUE;
}


sub go_forward {
  my $self = shift;

  return unless $self->can_forward;

  $self->save_scroll_pos;
  $self->trail_index($self->trail_index + 1);
  $self->load_topic;
}


sub is_home {
  my $self = shift;

  my $trail = $self->trail;
  return FALSE unless @$trail;

  my $i = $self->trail_index;

  return $trail->[$i]->[0] eq HOME_TOPIC
}


sub load_topic {
  my $self = shift;

  my $i = $self->trail_index;
  my($topic, $pos) = @{$self->trail->[$i]};

  $self->clear;
  $self->status_message('');
  $self->set_button_states;

  my $parser = $self->app->factory->make_class('/app/help_parser', $self);
  $parser->parse_topic($topic);
  if($parser->content_seen) {
    $self->textview->get_visible_rect;
    $self->textview->parent->get_vadjustment->set_value($pos);
    $self->app->add_idle_handler(
      sub { # do it again when the widget is drawn
        $self->textview->parent->get_vadjustment->set_value($pos);
        return FALSE; 
      }
    );
    return;
  }

  $self->add_tagged_text("Unable to find help for topic '$topic'", 0, ['head3']);
}


sub clear {
  my $self = shift;

  $self->buffer->set_text('');
  my $tag_table = $self->buffer->get_tag_table;
  $tag_table->foreach(sub { $tag_table->remove($_[0]) if $_[0]->{link_type}; });
}


sub set_button_states {
  my $self = shift;

  $self->back_button->set(sensitive => $self->can_back);
  $self->forward_button->set(sensitive => $self->can_forward);
  $self->home_button->set(sensitive => !$self->is_home);

  $self->back_menuitem->set(sensitive => $self->can_back);
  $self->forward_menuitem->set(sensitive => $self->can_forward);
  $self->home_menuitem->set(sensitive => !$self->is_home);
}


sub link_data {
  my $self = shift;

  $self->{link_type}   = shift;
  $self->{link_target} = shift;
}


sub add_tagged_text {
  my($self, $text, $indent, $tag_names) = @_;

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

  push @tags, $self->{tag}->{"indent$indent"} if $indent> 0;

  my $iter = $buffer->get_end_iter;
  $buffer->insert_with_tags($iter, $text, @tags);
}


sub status_message {
  my($self, $message)= @_;
  
  return unless defined $message;

  my $statusbar = $self->statusbar;
  $statusbar->pop(0);
  $statusbar->push(0, $message);
}


########################### GUI Event Handlers ###############################

sub on_size_allocate {
  my($self, $window, $rect) = @_;

  my($width, $height) = ($rect->width, $rect->height);

  my $app = $self->app;
  my $def_width  = $app->get_pref('help_win.width')  || DEFAULT_WIDTH;
  my $def_height = $app->get_pref('help_win.height') || DEFAULT_HEIGHT;
  if($def_width != $width) {
    $app->set_pref('help_win.width', $width);
  }
  if($def_height != $height) {
    $app->set_pref('help_win.height', $height);
  }
}


sub on_close_activated {
  my $self = shift;

  $self->helpwin->destroy;
}


sub on_reload_activated {
  my $self = shift;

  $self->save_scroll_pos;
  $self->load_topic;
}


sub on_find_activated {
  my $self = shift;

  $self->status_message('Find not implemented');
}


sub on_back_activated {
  my $self = shift;

  $self->go_back;
}


sub on_forward_activated {
  my $self = shift;

  $self->go_forward;
}


sub on_home_activated {
  my $self = shift;

  $self->go_to_topic(HOME_TOPIC);
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
    $self->status_message(
      "'$link->{link_type}' links not implemented - try copy and paste"
    );
    return FALSE;
  }
  
  $self->app->add_idle_handler(
    sub { $self->go_to_topic($link->{link_target}); return FALSE; }
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
  <property name="default_width"><% default_width %></property>
  <property name="default_height"><% default_height %></property>
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
	<widget class="GtkMenuBar" id="menubar">
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

		  <child>
		    <widget class="GtkImageMenuItem" id="reload_menuitem">
		      <property name="visible">True</property>
		      <property name="label" translatable="yes">_Reload</property>
		      <property name="use_underline">True</property>
		      <signal name="activate" handler="on_reload_activated" last_modification_time="Sun, 08 May 2005 10:15:21 GMT"/>
		      <accelerator key="R" modifiers="GDK_CONTROL_MASK" signal="activate"/>

		      <child internal-child="image">
			<widget class="GtkImage" id="image3">
			  <property name="visible">True</property>
			  <property name="stock">gtk-refresh</property>
			  <property name="icon_size">1</property>
			  <property name="xalign">0.5</property>
			  <property name="yalign">0.5</property>
			  <property name="xpad">0</property>
			  <property name="ypad">0</property>
			</widget>
		      </child>
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
		      <property name="label" translatable="yes">_Back</property>
		      <property name="use_underline">True</property>
		      <signal name="activate" handler="on_back_activated" last_modification_time="Sun, 08 May 2005 10:15:21 GMT"/>
		      <accelerator key="Left" modifiers="GDK_MOD1_MASK" signal="activate"/>

		      <child internal-child="image">
			<widget class="GtkImage" id="image4">
			  <property name="visible">True</property>
			  <property name="stock">gtk-go-back</property>
			  <property name="icon_size">1</property>
			  <property name="xalign">0.5</property>
			  <property name="yalign">0.5</property>
			  <property name="xpad">0</property>
			  <property name="ypad">0</property>
			</widget>
		      </child>
		    </widget>
		  </child>

		  <child>
		    <widget class="GtkImageMenuItem" id="forward_menuitem">
		      <property name="visible">True</property>
		      <property name="label" translatable="yes">_Forward</property>
		      <property name="use_underline">True</property>
		      <signal name="activate" handler="on_forward_activated" last_modification_time="Sun, 08 May 2005 10:15:21 GMT"/>
		      <accelerator key="Right" modifiers="GDK_MOD1_MASK" signal="activate"/>

		      <child internal-child="image">
			<widget class="GtkImage" id="image5">
			  <property name="visible">True</property>
			  <property name="stock">gtk-go-forward</property>
			  <property name="icon_size">1</property>
			  <property name="xalign">0.5</property>
			  <property name="yalign">0.5</property>
			  <property name="xpad">0</property>
			  <property name="ypad">0</property>
			</widget>
		      </child>
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
		      <property name="label" translatable="yes">_Home</property>
		      <property name="use_underline">True</property>
		      <signal name="activate" handler="on_home_activated" last_modification_time="Sun, 08 May 2005 10:15:21 GMT"/>
		      <accelerator key="Home" modifiers="GDK_MOD1_MASK" signal="activate"/>

		      <child internal-child="image">
			<widget class="GtkImage" id="image6">
			  <property name="visible">True</property>
			  <property name="stock">gtk-home</property>
			  <property name="icon_size">1</property>
			  <property name="xalign">0.5</property>
			  <property name="yalign">0.5</property>
			  <property name="xpad">0</property>
			  <property name="ypad">0</property>
			</widget>
		      </child>
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

