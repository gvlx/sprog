package Sprog::Gear::ReplaceFile;

=begin sprog-gear-metadata

  title: Replace File
  type_in: P
  type_out: _

=end sprog-gear-metadata

=cut

use strict;

use base qw(
  Sprog::Gear::OutputToFH
  Sprog::Gear
);

__PACKAGE__->declare_properties(
  suffix  => '.bak',
);


use File::Spec;
use File::Temp;


sub file_start {
  my($self, $filename) = @_;

  my @path = File::Spec->splitpath($filename);
  $path[-1] = 'spXXXXX';
  my $template = File::Spec->catpath(@path);

  my($fh, $name) = mkstemps($template, '.tmp');
  if(!$fh) {
    return $self->alert(
      'Error opening temporary file', "mkstemps($template.tmp'): $!"
    );
  }
  $self->fh_out($fh);

  $self->{_tempfile} = $name;
}


sub file_end {
  my($self, $filename) = @_;

  $self->_close_output_fh;

  if(my $suffix = $self->suffix) {
    rename $filename, $filename . $suffix;
  }
  else {
    unlink($filename);
  }
  rename delete($self->{_tempfile}), $filename
}


sub dialog_xml {
#  return 'file:/home/grant/projects/sf/sprog/glade/replacefile.glade';
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
	  <property name="border_width">5</property>
	  <property name="visible">True</property>
	  <property name="n_rows">1</property>
	  <property name="n_columns">2</property>
	  <property name="homogeneous">False</property>
	  <property name="row_spacing">0</property>
	  <property name="column_spacing">0</property>

	  <child>
	    <widget class="GtkLabel" id="">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Backup Suffix:</property>
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
	      <property name="x_padding">2</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkEntry" id="PAD.suffix">
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
	      <property name="x_padding">2</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>
	</widget>
	<packing>
	  <property name="padding">2</property>
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

Sprog::Gear::ReplaceFile - Overwrite the original file with new data

=head1 DESCRIPTION

This is a data output gear.  It is used to replace the contents of the input
file with the output of the machine.

Since we can't really overwrite the same file we're reading from, output is
actually written to a temporary file.  The files are renamed in the C<file_end>
event.

=head1 COPYRIGHT 

Copyright 2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Replace File Gear

The 'Replace File' gear is used to save the output of a machine by overwriting
the original input file.  This is sometimes called an 'in-place edit'.

By default, the original file contents will be preserved in a backup file, but
if you don't want your hard disk littered with F<.bak> files you can turn that
off.

=head2 Properties

The Write File gear has only one property:

=over 4

=item Backup Suffix

This property controls whether a backup of the original input file will be kept
and if so, what suffix will be added to it.

The default value is F<.bak> so for example, an input file called F<phonelist.txt> will be saved to F<phonelist.txt.bak>.

If you leave the entry box blank, no backup copy of the original file will be
retained.

=back

=end :sprog-help-text

