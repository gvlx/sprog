package Sprog::Gear::StripWhitespace;

=begin sprog-gear-metadata

  title: Strip Whitespace
  type_in: A
  type_out: A

=end sprog-gear-metadata

=cut

use strict;
use warnings;

use base qw(Sprog::Gear);

__PACKAGE__->declare_properties(
  strip_leading   => 1,
  strip_trailing  => 1,
  collapse_spaces => 0,
  collapse_lines  => 0,
  strip_all       => 0,
);


sub row {
  my($self, $r) = @_;

  my @f = @$r; # make a copy
  foreach (@f) {
    s/[\r\n]+/ /g   if $self->{collapse_lines};
    if($self->{strip_all}) {
      s/[ \t]+//g;
    }
    else {
      s/\t+/ /g       if $self->{collapse_spaces};
      s/[ \t]{2,}/ /g if $self->{collapse_spaces};
      s/\A[ \t]+//    if $self->{strip_leading};
      s/[ \t]+\Z//    if $self->{strip_trailing};
    }
  }

  $self->msg_out(row => \@f);
}


sub dialog_xml {
#  return 'file:/home/grant/projects/sf/sprog/glade/stripwhitespace.glade';
  return <<'END_XML';
<?xml version="1.0" standalone="no"?> <!--*- mode: xml -*-->
<!DOCTYPE glade-interface SYSTEM "http://glade.gnome.org/glade-2.0.dtd">

<glade-interface>

<widget class="GtkDialog" id="properties">
  <property name="visible">True</property>
  <property name="title" translatable="yes">Properties</property>
  <property name="type">GTK_WINDOW_TOPLEVEL</property>
  <property name="window_position">GTK_WIN_POS_NONE</property>
  <property name="modal">False</property>
  <property name="resizable">True</property>
  <property name="destroy_with_parent">False</property>
  <property name="decorated">True</property>
  <property name="skip_taskbar_hint">False</property>
  <property name="skip_pager_hint">False</property>
  <property name="type_hint">GDK_WINDOW_TYPE_HINT_DIALOG</property>
  <property name="gravity">GDK_GRAVITY_NORTH_WEST</property>
  <property name="has_separator">True</property>

  <child internal-child="vbox">
    <widget class="GtkVBox" id="dialog-vbox2">
      <property name="visible">True</property>
      <property name="homogeneous">False</property>
      <property name="spacing">0</property>

      <child internal-child="action_area">
	<widget class="GtkHButtonBox" id="dialog-action_area2">
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
	    <widget class="GtkButton" id="cancelbutton2">
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
	    <widget class="GtkButton" id="okbutton2">
	      <property name="visible">True</property>
	      <property name="can_default">True</property>
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
		<widget class="GtkCheckButton" id="PAD.strip_leading">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Strip leading whitespace</property>
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
		<widget class="GtkCheckButton" id="PAD.strip_trailing">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Strip trailing whitespace</property>
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
		<widget class="GtkCheckButton" id="PAD.collapse_spaces">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Collapse multiple space</property>
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
		<widget class="GtkCheckButton" id="PAD.collapse_lines">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Collapse newlines</property>
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
		<widget class="GtkCheckButton" id="PAD.strip_all">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Strip all whitespace</property>
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
	    </widget>
	    <packing>
	      <property name="left_attach">0</property>
	      <property name="right_attach">1</property>
	      <property name="top_attach">0</property>
	      <property name="bottom_attach">1</property>
	      <property name="x_options">expand</property>
	      <property name="y_options"></property>
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

Sprog::Gear::StripWhitespace - Remove selected whitespace from fields in each row

=head1 DESCRIPTION

Passes all fields from list input to list output but removes selected
whitespace enroute.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Strip Whitespace Gear

This gear allows you to remove some or all whitespace characters from each
field of each row received from the 'list' input connector.  All fields
are passed out the 'list' output connector.

=head2 Properties

You can choose any combination of the following on/off properties:

=over 4

=item Strip Leading Whitespace

Removes all space or tab characters at the start of each field.

=item Strip Trailing Whitespace

Removes all space or tab characters at the end of each field.

=item Collapse Multiple Spaces

Within a field (ie: not just at the beginning or end), replace any tab or any
sequence of two or more consecutive space or tab characters with a single space

=item Collapse Newlines

When this option is turned on, each newline character will be changed to a
single space.

=item Strip All Whitespace

If this option is turned on, all spaces, tabs and optionally newlines will be
removed, regardless of whether they are at the start, end or middle of a field.

=back

=end :sprog-help-text

