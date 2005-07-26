package Sprog::Gear::ReadFile;

=begin sprog-gear-metadata

  title: Read File
  type_in: _
  type_out: P

=end sprog-gear-metadata

=cut

use strict;

use base qw(
  Sprog::Mixin::InputFromFH
  Sprog::Gear
);

__PACKAGE__->declare_properties(
  filename   =>  '',
);


sub engage {
  my($self) = @_;

  my $fh = $self->_open_file or return;
  $self->fh_in($fh);

  return $self->SUPER::engage;
}


sub _open_file {
  my($self) = @_;

  my $filename = $self->filename;
  if(!defined($filename) or $filename !~ /\S/) {
    $self->alert('You must select an input file');
    return;
  }

  my($fh);
  if(!open $fh, '<', $filename) {
    $self->alert(qq(Can't open "$filename"), "$!");
    return;
  }
  $self->msg_out(file_start => $filename);

  return $fh;
}


sub accept_dropped_uris {
  my $self = shift;

  if(@_ > 1) {
    $self->alert('This gear can only accept one filename');
    return;
  }

  my $filename = shift;
  return unless length $filename;

  if(not $filename =~ s{^file://}{}) {
    $self->alert(
      "Unsupported file path", "Expected 'file:///...'\nGot '$filename'"
    );
    return;
  }

  $self->filename($filename);
  $self->has_error(0);

  return 1;
}

sub dialog_xml {
#  return 'file:/home/grant/projects/sprog/glade/readfile.glade';
  return <<'END_XML';
<?xml version="1.0" standalone="no"?> <!--*- mode: xml -*-->
<!DOCTYPE glade-interface SYSTEM "http://glade.gnome.org/glade-2.0.dtd">

<glade-interface>

<widget class="GtkDialog" id="properties">
  <property name="title" translatable="yes">Properties</property>
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
	<widget class="GtkTable" id="table1">
	  <property name="border_width">5</property>
	  <property name="visible">True</property>
	  <property name="n_rows">2</property>
	  <property name="n_columns">2</property>
	  <property name="homogeneous">False</property>
	  <property name="row_spacing">0</property>
	  <property name="column_spacing">0</property>

	  <child>
	    <widget class="GtkEntry" id="PAD.filename">
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
	      <property name="label" translatable="yes">Filename:</property>
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
	      <property name="x_padding">5</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkButton" id="PAD.browse_to_entry(filename)">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="label" translatable="yes"> Browse </property>
	      <property name="use_underline">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
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

Sprog::Gear::ReadFile - Read data from a file

=head1 DESCRIPTION

This is a data input gear.  It reads data from a file and passes it downstream
using a 'pipe' connector.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Read File Gear

The 'Read File' gear allows you to read data from a file and pass it out
through a 'pipe' connector.

You would usually use this gear to read text files, but it can also be used
for 'binary' files such as images.

=head2 Properties

The Read File gear has only one property - the name of the file to read.  You
can set the filename property in three ways:

=over 4

=item * 

by typing the name of a file

=item * 

by using the B<Browse> button and selecting a file

=item * 

by dragging a file and dropping into the Sprog window

=back

=head2 See Also

Instead of reading data directly from a file, you might want to consider
capturing the output of another command using the 
L<Run Command|Sprog::Gear::CommandIn> gear.

=end :sprog-help-text

