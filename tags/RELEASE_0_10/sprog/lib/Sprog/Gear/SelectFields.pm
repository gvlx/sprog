package Sprog::Gear::SelectFields;

=begin sprog-gear-metadata

  title: Select Fields
  type_in: H
  type_out: A

=end sprog-gear-metadata

=cut

use strict;
use warnings;

use base qw(Sprog::Gear);

__PACKAGE__->declare_properties(
  fields => '',
);


sub engage {
  my $self = shift;

  delete $self->{_fields};
  local($_) = $self->fields;
  return $self->alert('You must select some fields') unless(/\S/);

  my @fields = map { s/^\s+//; s/\s+$//; $_ } split /,/;

  $self->{_fields} = \@fields;
}


sub record {
  my($self, $rec) = @_;

  my @row = map { defined($_) ? $_ : '' } @{$rec}{@{$self->{_fields}}};

  $self->msg_out(row => \@row);
}


sub dialog_xml {
#  return 'file:/home/grant/projects/sf/sprog/glade/select_fields.glade';
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
	  <property name="visible">True</property>
	  <property name="n_rows">2</property>
	  <property name="n_columns">2</property>
	  <property name="homogeneous">False</property>
	  <property name="row_spacing">0</property>
	  <property name="column_spacing">0</property>

	  <child>
	    <widget class="GtkEntry" id="PAD.fields">
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
	      <property name="left_attach">1</property>
	      <property name="right_attach">2</property>
	      <property name="top_attach">0</property>
	      <property name="bottom_attach">1</property>
	      <property name="x_padding">5</property>
	      <property name="y_padding">5</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Fields:</property>
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
	      <property name="x_padding">5</property>
	      <property name="y_padding">5</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="label1">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">eg: name,address,phone</property>
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
	      <property name="top_attach">1</property>
	      <property name="bottom_attach">2</property>
	      <property name="x_padding">5</property>
	      <property name="x_options">fill</property>
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


=head1 NAME

Sprog::Gear::SelectFields - Select fields from each record

=head1 DESCRIPTION

Converts records to lists by passing only the selected fields.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Select Fields Gear

This gear allows you to convert data from the 'record' input connector into a
form suitable for the 'list' output connector.  You simply need to list the
fields you wish to pass through in the order you want them.

=head2 Properties

The Select Fields gear has only one property - the list of fields which should
be passed through.  Enter field names as a comma separated list.  

Leading and trailing spaces around fieldnames will be trimmed, but otherwise
the field names will be used exactly as typed.

I<Remember, field name are case sensitive>.

=end :sprog-help-text

