package Sprog::Gear::TextInput;

=begin sprog-gear-metadata

  title: Text Input
  type_in: _
  type_out: P

=end sprog-gear-metadata

=cut

use strict;

use base qw(Sprog::Gear::Top);

__PACKAGE__->declare_properties(
  text => '',
);

__PACKAGE__->mk_accessors(qw(
  gear_view
));

use Scalar::Util qw(weaken);

sub title         { 'Text Input'; };

sub prime {
  my $self = shift;

  $self->machine->register_data_provider($self);
  return $self->SUPER::prime;
}


sub send_data {
  my($self, $data) = @_;

  $self->msg_out(file_start => undef);
  $self->msg_out(data       => $self->text);
  $self->msg_out(file_end   => undef);
  $self->machine->unregister_data_provider($self);
}


sub dialog_xml {
  #return 'file:/home/grant/projects/sf/sprog/glade/textinput.glade';
  return <<'END_XML';
<?xml version="1.0" standalone="no"?> <!--*- mode: xml -*-->
<!DOCTYPE glade-interface SYSTEM "http://glade.gnome.org/glade-2.0.dtd">

<glade-interface>

<widget class="GtkDialog" id="properties">
  <property name="title" translatable="yes">Properties</property>
  <property name="type">GTK_WINDOW_TOPLEVEL</property>
  <property name="window_position">GTK_WIN_POS_MOUSE</property>
  <property name="modal">False</property>
  <property name="default_width">480</property>
  <property name="default_height">360</property>
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
	<widget class="GtkTable" id="table2">
	  <property name="visible">True</property>
	  <property name="n_rows">2</property>
	  <property name="n_columns">1</property>
	  <property name="homogeneous">False</property>
	  <property name="row_spacing">0</property>
	  <property name="column_spacing">0</property>

	  <child>
	    <widget class="GtkLabel" id="label1">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Text Input:</property>
	      <property name="use_underline">False</property>
	      <property name="use_markup">False</property>
	      <property name="justify">GTK_JUSTIFY_LEFT</property>
	      <property name="wrap">False</property>
	      <property name="selectable">False</property>
	      <property name="xalign">0</property>
	      <property name="yalign">0.5</property>
	      <property name="xpad">10</property>
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
	    <widget class="GtkScrolledWindow" id="scrolledwindow1">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="hscrollbar_policy">GTK_POLICY_AUTOMATIC</property>
	      <property name="vscrollbar_policy">GTK_POLICY_AUTOMATIC</property>
	      <property name="shadow_type">GTK_SHADOW_IN</property>
	      <property name="window_placement">GTK_CORNER_TOP_LEFT</property>

	      <child>
		<widget class="GtkTextView" id="PAD.text">
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
	      <property name="left_attach">0</property>
	      <property name="right_attach">1</property>
	      <property name="top_attach">1</property>
	      <property name="bottom_attach">2</property>
	      <property name="x_padding">10</property>
	      <property name="y_padding">10</property>
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

Sprog::Gear::TextInput - Sprog data source, type data into a text input

=head1 DESCRIPTION

This is a data input gear that's mostly useful for testing.  It simply takes
data that the user types into a multi-line text entry and passes it downstream
using a 'pipe' connector.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Text Input Gear

The 'Text Input' gear is mostly useful for testing.  If you have some test data
you want to feed into a machine, you can simply paste the data into this gear's
text entry (rather than say saving it in a file).  The contents of the text
entry are passed out through a 'pipe' connector.

=head2 Properties

The Text Input gear has only one property - the text.  You can type into the
text entry box or paste from the clipboard.

=end :sprog-help-text

