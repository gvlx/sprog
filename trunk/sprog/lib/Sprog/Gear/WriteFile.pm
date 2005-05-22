package Sprog::Gear::WriteFile;

=begin sprog-gear-metadata

  title: Write File
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
  filename  => '',
  if_exists => 'confirm',
);


sub engage {
  my($self) = @_;

  my $fh = $self->_open_output_file or return;
  $self->fh_out($fh);

  return $self->SUPER::engage;
}


sub _open_output_file {
  my($self) = @_;

  my $filename = $self->filename;
  if(!defined($filename) or $filename !~ /\S/) {
    $self->app->alert('You must select an output file');
    return;
  }

  my $mode = '>';
  if(-e $filename) {
    my $action = $self->if_exists || 'confirm';
    if($action eq 'confirm') {
      return unless $self->app->confirm_yes_no(
        "File already exists!\n\nOverwrite $filename?"
      );
    }
    elsif($action eq 'append') {
      $mode = '>>';
    }
  }

  my($fh);
  if(!open $fh, $mode, $filename) {
    $self->app->alert(qq(Can't open "$filename"), "$!");
    return;
  }

  return $fh;
}


sub dialog_xml {
#  return 'file:/home/grant/projects/sf/sprog/glade/writefile.glade';
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
	  <property name="n_rows">3</property>
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

	  <child>
	    <widget class="GtkVBox" id="vbox1">
	      <property name="visible">True</property>
	      <property name="homogeneous">False</property>
	      <property name="spacing">0</property>

	      <child>
		<widget class="GtkRadioButton" id="PAD.if_exists.confirm">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Confirm before overwriting an existing file</property>
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
		<widget class="GtkRadioButton" id="PAD.if_exists.overwrite">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Overwrite an existing file with no warnings</property>
		  <property name="use_underline">True</property>
		  <property name="relief">GTK_RELIEF_NORMAL</property>
		  <property name="focus_on_click">True</property>
		  <property name="active">False</property>
		  <property name="inconsistent">False</property>
		  <property name="draw_indicator">True</property>
		  <property name="group">PAD.if_exists.confirm</property>
		</widget>
		<packing>
		  <property name="padding">0</property>
		  <property name="expand">False</property>
		  <property name="fill">False</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkRadioButton" id="PAD.if_exists.append">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Always append to an existing file</property>
		  <property name="use_underline">True</property>
		  <property name="relief">GTK_RELIEF_NORMAL</property>
		  <property name="focus_on_click">True</property>
		  <property name="active">False</property>
		  <property name="inconsistent">False</property>
		  <property name="draw_indicator">True</property>
		  <property name="group">PAD.if_exists.confirm</property>
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
	      <property name="right_attach">2</property>
	      <property name="top_attach">2</property>
	      <property name="bottom_attach">3</property>
	      <property name="x_padding">4</property>
	      <property name="y_padding">2</property>
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

Sprog::Gear::WriteFile - Write data to a file

=head1 DESCRIPTION

This is a data output gear.  It reads data from 'pipe' connector and writes it
out to a file.

=head1 COPYRIGHT 

Copyright 2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Write File Gear

The 'Write File' gear takes data from a 'pipe' connector and writes it out to a
file.

=head2 Properties

The Write File gear has two properties: the name of the file to write and an
action to take if the file already exists:

=over 4

=item Filename

You can set the name of the file to write by typing it or by using the
B<Browse> button and selecting a file.

=item If File Exists

You have three options for what to do if the file you selected already exists:

B<Confirm> - you will be asked each time to confirm whether the file should be
overwritten.  If you answer 'No', the machine will be stopped.

B<Overwrite> - the file will be overwritten without any confirmation.

B<Append> - the data will be added to the end of the existing file.

=back

=end :sprog-help-text

