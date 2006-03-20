package Sprog::Gear::ImageBorder;

=begin sprog-gear-metadata

  title: Add Border to Image
  type_in: P
  type_out: P

=end sprog-gear-metadata

=cut

use strict;

use base qw(
  Sprog::Gear::SlurpFile
  Sprog::Gear
);

__PACKAGE__->declare_properties(
  colour   => '#000000000000',
  width    => 1,
);

use Imager;


sub file_data {
  my($self, $data, $filename) = @_;

  eval { $self->_add_border($data, $filename) };
  return $self->alert("Error in image transformation", "$@") if $@;
}


sub _add_border {
  my($self, $data, $filename) = @_;

  my($type) = ($filename =~ /\.(\w+)$/);
  return $self->alert("Can't get image type from file suffix") unless $type;

  my $src = Imager->new();

  $src->open(data => $data) or die $src->errstr();

  my $bw = $self->width;
  my $sw = $src->getwidth;
  my $sh = $src->getheight;

  my $dw = $sw + 2 * $bw;
  my $dh = $sh + 2 * $bw;

  my $dst = Imager->new(xsize => $dw, ysize => $dh, channels => 4);

  my @rgb = map { int(hex($_) / 257) } $self->colour =~ /#(....)(....)(....)/;
  my $black = Imager::Color->new(@rgb);

  $dst->box(color => $black, xmin => 0, ymin => 0, xmax => $dw, ymax => $dh, filled => 1);

  $dst->paste(left => $bw, top => $bw, img => $src);

  $dst->write(
    callback => sub { $self->msg_out(data => shift); },
    type => $type,
  ) or die $dst->errstr();
}


sub dialog_xml {
#  return 'file:/home/grant/projects/sf/sprog/glade/imageborder.glade';
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
	<widget class="GtkHBox" id="hbox1">
	  <property name="visible">True</property>
	  <property name="homogeneous">False</property>
	  <property name="spacing">0</property>

	  <child>
	    <widget class="GtkTable" id="table2">
	      <property name="border_width">4</property>
	      <property name="visible">True</property>
	      <property name="n_rows">2</property>
	      <property name="n_columns">2</property>
	      <property name="homogeneous">False</property>
	      <property name="row_spacing">2</property>
	      <property name="column_spacing">10</property>

	      <child>
		<widget class="GtkLabel" id="label1">
		  <property name="visible">True</property>
		  <property name="label" translatable="yes">Border Colour:</property>
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
		  <property name="x_options">fill</property>
		  <property name="y_options"></property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkLabel" id="label2">
		  <property name="visible">True</property>
		  <property name="label" translatable="yes">Border Width:</property>
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
		  <property name="top_attach">1</property>
		  <property name="bottom_attach">2</property>
		  <property name="x_options">fill</property>
		  <property name="y_options"></property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkColorButton" id="PAD.colour">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="use_alpha">False</property>
		  <property name="focus_on_click">True</property>
		</widget>
		<packing>
		  <property name="left_attach">1</property>
		  <property name="right_attach">2</property>
		  <property name="top_attach">0</property>
		  <property name="bottom_attach">1</property>
		  <property name="x_options">fill</property>
		  <property name="y_options"></property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkSpinButton" id="PAD.width">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="climb_rate">1</property>
		  <property name="digits">0</property>
		  <property name="numeric">True</property>
		  <property name="update_policy">GTK_UPDATE_ALWAYS</property>
		  <property name="snap_to_ticks">False</property>
		  <property name="wrap">False</property>
		  <property name="adjustment">1 1 10000 1 10 10</property>
		</widget>
		<packing>
		  <property name="left_attach">1</property>
		  <property name="right_attach">2</property>
		  <property name="top_attach">1</property>
		  <property name="bottom_attach">2</property>
		  <property name="y_options"></property>
		</packing>
	      </child>
	    </widget>
	    <packing>
	      <property name="padding">0</property>
	      <property name="expand">True</property>
	      <property name="fill">False</property>
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

Sprog::Gear::ImageBorder - Add a border to an image

=head1 DESCRIPTION

This is an experimental (proof-of-concept) gear for manipulating Image data in
Sprog.  Given a stream of data from an image file, it will add a border of the
specified width (pixels) in the specified colour and write out the resulting
bitstream to the next downstream gear.

This gear has not been extensively tested with different image formats.  It is
known to work with PNG images but may convert indexed colour images to 24 bit
RGB.

=head1 SEE ALSO

This gear uses the L<Imager> module.

=head1 COPYRIGHT 

Copyright 2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Add Border to Image Gear

This gear takes a stream of image data (presumably read from a file) and adds
a rectangular solid coloured border to the image.

I<Warning this is just a proof-of-concept implementation.  It will be replaced
with a more robust version soon>.

=head2 Properties

This gear has two properties:

=over 4

=item Border Colour

The default border colour is black.  To change it, click the colour swatch
button and select a colour.

=item Border Width

The default border width is 1 pixel.  When this gear adds a 1-pixel wide border
to the top, bottom, left and right sides, the resulting image will be 2 pixels
wider and 2 pixels taller than the original image.

=back

=end :sprog-help-text

