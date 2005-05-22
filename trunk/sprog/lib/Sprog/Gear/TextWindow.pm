package Sprog::Gear::TextWindow;

=begin sprog-gear-metadata

  title: Text Window
  type_in: P
  type_out: _
  view_subclass: TextWindow

=end sprog-gear-metadata

=cut

use strict;

use base qw(Sprog::Gear);

__PACKAGE__->declare_properties(
  clear_on_run      => 1, 
  auto_scroll       => 0,
  show_start_events => 0, 
  show_end_events   => 0
);

__PACKAGE__->mk_accessors(qw(
  gear_view
));

use Scalar::Util qw(weaken);

sub engage {
  my $self = shift;

  my $gear_view = $self->app->view->gear_view_by_id($self->id);
  $self->gear_view($gear_view);
  weaken($self->{gear_view});
  $gear_view->clear if $self->clear_on_run;

  return $self->SUPER::engage;
}


sub data {
  my($self, $data) = @_;

  $self->gear_view->add_data($data);
}


sub file_start {
  my($self, $filename) = @_;

  return unless $self->show_start_events;
  $filename = '' unless defined $filename;
  $self->gear_view->add_data("----- File start: $filename -----\n");
}


sub file_end {
  my($self, $filename) = @_;

  return unless $self->show_end_events;
  $filename = '' unless defined $filename;
  $self->gear_view->add_data("----- File end:   $filename -----\n");
}


sub dialog_xml {
#  return 'file:/home/grant/projects/sprog/glade/textwindow.glade';
  return <<'END_XML';
<?xml version="1.0" standalone="no"?> <!--*- mode: xml -*-->
<!DOCTYPE glade-interface SYSTEM "http://glade.gnome.org/glade-2.0.dtd">

<glade-interface>

<widget class="GtkDialog" id="properties">
  <property name="title" translatable="yes">Properties</property>
  <property name="type">GTK_WINDOW_TOPLEVEL</property>
  <property name="window_position">GTK_WIN_POS_MOUSE</property>
  <property name="modal">False</property>
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
	<widget class="GtkTable" id="table1">
	  <property name="border_width">10</property>
	  <property name="visible">True</property>
	  <property name="n_rows">1</property>
	  <property name="n_columns">1</property>
	  <property name="homogeneous">False</property>
	  <property name="row_spacing">0</property>
	  <property name="column_spacing">0</property>

	  <child>
	    <widget class="GtkVBox" id="vbox1">
	      <property name="visible">True</property>
	      <property name="homogeneous">False</property>
	      <property name="spacing">0</property>

	      <child>
		<widget class="GtkCheckButton" id="PAD.clear_on_run">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Clear _window on each run</property>
		  <property name="use_underline">True</property>
		  <property name="relief">GTK_RELIEF_NORMAL</property>
		  <property name="focus_on_click">True</property>
		  <property name="active">False</property>
		  <property name="inconsistent">False</property>
		  <property name="draw_indicator">True</property>
		  <accelerator key="W" modifiers="GDK_MOD1_MASK" signal="clicked"/>
		</widget>
		<packing>
		  <property name="padding">0</property>
		  <property name="expand">False</property>
		  <property name="fill">False</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkCheckButton" id="PAD.auto_scroll">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">_Auto-scroll to show last line</property>
		  <property name="use_underline">True</property>
		  <property name="relief">GTK_RELIEF_NORMAL</property>
		  <property name="focus_on_click">True</property>
		  <property name="active">False</property>
		  <property name="inconsistent">False</property>
		  <property name="draw_indicator">True</property>
		</widget>
		<packing>
		  <property name="padding">0</property>
		  <property name="expand">False</property>
		  <property name="fill">False</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkCheckButton" id="PAD.show_start_events">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Show file _start events</property>
		  <property name="use_underline">True</property>
		  <property name="relief">GTK_RELIEF_NORMAL</property>
		  <property name="focus_on_click">True</property>
		  <property name="active">False</property>
		  <property name="inconsistent">False</property>
		  <property name="draw_indicator">True</property>
		  <accelerator key="S" modifiers="GDK_MOD1_MASK" signal="clicked"/>
		</widget>
		<packing>
		  <property name="padding">0</property>
		  <property name="expand">False</property>
		  <property name="fill">False</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkCheckButton" id="PAD.show_end_events">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Show file _end events</property>
		  <property name="use_underline">True</property>
		  <property name="relief">GTK_RELIEF_NORMAL</property>
		  <property name="focus_on_click">True</property>
		  <property name="active">False</property>
		  <property name="inconsistent">False</property>
		  <property name="draw_indicator">True</property>
		  <accelerator key="E" modifiers="GDK_MOD1_MASK" signal="clicked"/>
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
	      <property name="top_attach">0</property>
	      <property name="bottom_attach">1</property>
	      <property name="x_options">fill</property>
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

__END__


=head1 NAME

Sprog::Gear::TextWindow - display text in a window

=head1 DESCRIPTION

This is a output gear.  It takes any data received through the 'Pipe' input
connector and displays it in a scrolling text window.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Text Window Gear

The 'Text Window' is for displaying the output from the machine.  Any data
that's received on the 'pipe' input connector is displayed in a scrollable
windows.  This gear is only intended to work with text, it probably won't do
anything useful with binary data.

=head2 Properties

The Text Window gear has four properties:

=over 4

=item Clear window on each run

This option is enabled by default.  Un-check the box to keep the data in the
output window even when you re-run the machine.

=item Auto-scroll to show last line

Turn this option on to have the text window automatically scroll as lines are
added to the bottom.

I<Note: this will make the machine run noticeably slower>.

=item Show file start events

Turn this option on to insert a one line message to mark the start of each
file.

=item Show file end events

Turn this option on to insert a one line message to mark the end of each file.

=back

=head2 Text Window Controls

The text window will pop up as soon as it receives some text to display.  That
might not be until some time after your machine starts running - depending on
what sort of filtering you're using.

You can manually pop-up the window at any time by right-clicking on the gear
and selecting 'Show text window'.

When the window is visible, you can use the 'Clear' button to discard the text
already displayed.  Or you can use the 'Hide' button to hide the window.  It 
will re-appear as soon as more data is received.

To copy data from the text window, click and drag to highlight it with the 
mouse and then press Ctrl-C or right click and select 'Copy'.

=end :sprog-help-text

