package Sprog::Gear::NameFields;

=begin sprog-gear-metadata

  title: Add Field Names
  type_in: A
  type_out: H
  keywords: hash keys

=end sprog-gear-metadata

=cut

use strict;
use warnings;

use base qw(Sprog::Gear);

__PACKAGE__->declare_properties(
  names => '',
);


sub engage {
  my $self = shift;

  delete $self->{_colnames};
  local($_) = $self->names;
  return $self->alert('You must enter some field names') unless(/\S/);
  my @names = map { s/^\s+//; s/\s+$//; $_ } split /,/;
  $self->{_colnames} = \@names;

  return $self->SUPER::engage;
}


sub row {
  my($self, $r) = @_;

  my @row = @$r;
  my %rec;
  foreach (@{$self->{_colnames}}) {
    $rec{$_} = shift(@row);
    $rec{$_} = '' unless defined $rec{$_};
  }
  $self->msg_out(record => \%rec);
}

sub dialog_xml {
#  return 'file:/home/grant/projects/sf/sprog/glade/name_fields.glade';
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
	  <property name="n_columns">1</property>
	  <property name="homogeneous">False</property>
	  <property name="row_spacing">0</property>
	  <property name="column_spacing">0</property>

	  <child>
	    <widget class="GtkEntry" id="PAD.names">
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
	      <property name="x_padding">5</property>
	      <property name="y_padding">5</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Field names:</property>
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

__END__


=head1 NAME

Sprog::Gear::NameFields - Assign column values to named hash keys

=head1 DESCRIPTION

Converts list input to record output by assigning columns to named fields.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Add Field Names Gear

This gear allows you to convert rows from the 'list' input connector into
records by assigning each column value to a named field.

=head2 Properties

This gear has only one property - the list of field names.  Simply type them
in, matching the order of the incoming columns.  Multiple field names should
be separated with commas, for example:

  surname, first_name, dob

Field names will be stripped of leading and trailing spaces but apart from that
will be used exactly as you typed them.

By convention, field names are all lowercase with underscores instead of spaces,
but you can ignore that convention if you prefer.

=head2 See Also

If your data has column names in the first row, you can simply use the
L<List to Record|Sprog::Gear::ListToRecord> gear instead of assigning field
names manually.

=end :sprog-help-text

