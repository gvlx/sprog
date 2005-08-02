package Sprog::Gear::ImageText;

=begin sprog-gear-metadata

  title: Add Text to Image
  type_in: P
  type_out: P

=end sprog-gear-metadata

=cut

use strict;

use base qw(
  Sprog::Mixin::SlurpFile
  Sprog::Gear
);

__PACKAGE__->declare_properties(
  text     => '',
  colour   => '#000000000000',
  voff     => 1,
  hoff     => 1,
  vpos     => 'top',
  hpos     => 'left',
);

use Imager;


sub file_data {
  my($self, $data, $filename) = @_;

  eval { $self->_add_text($data, $filename) };
  return $self->alert("Error in image transformation", "$@") if $@;
}


sub _add_text {
  my($self, $data, $filename) = @_;

  my($type) = ($filename =~ /\.(\w+)$/);
  return $self->alert("Can't get image type from file suffix") unless $type;

  $type = lc($type);
  $type = 'jpeg' if $type eq 'jpg';

  my $img = Imager->new();

  $img->open(data => $data) or die $img->errstr();

  my $font = Imager::Font->new(
    file  => '/usr/share/fonts/truetype/freefont/FreeSans.ttf',
    color => $self->rgb_colour,
    size  => 10,
  );

  my $w = $img->getwidth;
  my $h = $img->getheight;

  my $voff = $self->voff;
  my $hoff = $self->hoff;
  my $vpos = $self->vpos;
  my $hpos = $self->hpos;

  my($x, $y);

  if   ($vpos eq 'top')    { $y = $voff;      }
  elsif($vpos eq 'bottom') { $y = $h - $voff; }
  else                     { $y = $h / 2;     }

  if   ($hpos eq 'left')   { $x = $hoff;      }
  elsif($hpos eq 'right')  { $x = $w - $hoff; }
  else                     { $x = $w / 2;     }

  $font->align(
    string => $self->text,
    x      => $x, 
    y      => $y, 
    halign => $hpos,
    valign => $vpos,
    image  => $img,
    aa     => 1,
  );

  $img->write(
    callback => sub { $self->msg_out(data => shift); },
    type => $type,
    $type eq 'jpeg' ? (jpegquality => 90) : (),
  ) or die $img->errstr();
}


sub rgb_colour {
  my $self = shift;

  my @rgb = map { int(hex($_) / 257) } $self->colour =~ /#(....)(....)(....)/;
  return Imager::Color->new(@rgb);
}


sub dialog_xml {
#  return 'file:/home/grant/projects/sf/sprog/glade/imagetext.glade';
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
	<widget class="GtkTable" id="table1">
	  <property name="border_width">6</property>
	  <property name="visible">True</property>
	  <property name="n_rows">5</property>
	  <property name="n_columns">4</property>
	  <property name="homogeneous">False</property>
	  <property name="row_spacing">4</property>
	  <property name="column_spacing">4</property>

	  <child>
	    <widget class="GtkLabel" id="label1">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Text:</property>
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
	      <property name="label" translatable="yes">Text Colour:</property>
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
	    <widget class="GtkRadioButton" id="PAD.vpos.top">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="label" translatable="yes">Top</property>
	      <property name="use_underline">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <property name="focus_on_click">True</property>
	      <property name="active">False</property>
	      <property name="inconsistent">False</property>
	      <property name="draw_indicator">True</property>
	    </widget>
	    <packing>
	      <property name="left_attach">0</property>
	      <property name="right_attach">1</property>
	      <property name="top_attach">3</property>
	      <property name="bottom_attach">4</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkRadioButton" id="PAD.hpos.left">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="label" translatable="yes">Left</property>
	      <property name="use_underline">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <property name="focus_on_click">True</property>
	      <property name="active">False</property>
	      <property name="inconsistent">False</property>
	      <property name="draw_indicator">True</property>
	    </widget>
	    <packing>
	      <property name="left_attach">0</property>
	      <property name="right_attach">1</property>
	      <property name="top_attach">4</property>
	      <property name="bottom_attach">5</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkRadioButton" id="PAD.vpos.center">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="label" translatable="yes">Center</property>
	      <property name="use_underline">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <property name="focus_on_click">True</property>
	      <property name="active">False</property>
	      <property name="inconsistent">False</property>
	      <property name="draw_indicator">True</property>
	      <property name="group">PAD.vpos.top</property>
	    </widget>
	    <packing>
	      <property name="left_attach">1</property>
	      <property name="right_attach">2</property>
	      <property name="top_attach">3</property>
	      <property name="bottom_attach">4</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkRadioButton" id="PAD.hpos.center">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="label" translatable="yes">Center</property>
	      <property name="use_underline">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <property name="focus_on_click">True</property>
	      <property name="active">False</property>
	      <property name="inconsistent">False</property>
	      <property name="draw_indicator">True</property>
	      <property name="group">PAD.hpos.left</property>
	    </widget>
	    <packing>
	      <property name="left_attach">1</property>
	      <property name="right_attach">2</property>
	      <property name="top_attach">4</property>
	      <property name="bottom_attach">5</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkRadioButton" id="PAD.vpos.bottom">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="label" translatable="yes">Bottom</property>
	      <property name="use_underline">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <property name="focus_on_click">True</property>
	      <property name="active">False</property>
	      <property name="inconsistent">False</property>
	      <property name="draw_indicator">True</property>
	      <property name="group">PAD.vpos.top</property>
	    </widget>
	    <packing>
	      <property name="left_attach">2</property>
	      <property name="right_attach">3</property>
	      <property name="top_attach">3</property>
	      <property name="bottom_attach">4</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkRadioButton" id="PAD.hpos.right">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="label" translatable="yes">Right</property>
	      <property name="use_underline">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <property name="focus_on_click">True</property>
	      <property name="active">False</property>
	      <property name="inconsistent">False</property>
	      <property name="draw_indicator">True</property>
	      <property name="group">PAD.hpos.left</property>
	    </widget>
	    <packing>
	      <property name="left_attach">2</property>
	      <property name="right_attach">3</property>
	      <property name="top_attach">4</property>
	      <property name="bottom_attach">5</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="label6">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Offset:</property>
	      <property name="use_underline">False</property>
	      <property name="use_markup">False</property>
	      <property name="justify">GTK_JUSTIFY_LEFT</property>
	      <property name="wrap">False</property>
	      <property name="selectable">False</property>
	      <property name="xalign">0.5</property>
	      <property name="yalign">0.5</property>
	      <property name="xpad">0</property>
	      <property name="ypad">0</property>
	    </widget>
	    <packing>
	      <property name="left_attach">3</property>
	      <property name="right_attach">4</property>
	      <property name="top_attach">2</property>
	      <property name="bottom_attach">3</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkEntry" id="PAD.text">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="editable">True</property>
	      <property name="visibility">True</property>
	      <property name="max_length">0</property>
	      <property name="text" translatable="yes"></property>
	      <property name="has_frame">True</property>
	      <property name="invisible_char">*</property>
	      <property name="activates_default">False</property>
	    </widget>
	    <packing>
	      <property name="left_attach">1</property>
	      <property name="right_attach">4</property>
	      <property name="top_attach">0</property>
	      <property name="bottom_attach">1</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="label7">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Position:</property>
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
	      <property name="top_attach">2</property>
	      <property name="bottom_attach">3</property>
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
	      <property name="top_attach">1</property>
	      <property name="bottom_attach">2</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkSpinButton" id="PAD.voff">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="climb_rate">1</property>
	      <property name="digits">0</property>
	      <property name="numeric">True</property>
	      <property name="update_policy">GTK_UPDATE_ALWAYS</property>
	      <property name="snap_to_ticks">False</property>
	      <property name="wrap">False</property>
	      <property name="adjustment">1 0 10000 1 10 10</property>
	    </widget>
	    <packing>
	      <property name="left_attach">3</property>
	      <property name="right_attach">4</property>
	      <property name="top_attach">3</property>
	      <property name="bottom_attach">4</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkSpinButton" id="PAD.hoff">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="climb_rate">1</property>
	      <property name="digits">0</property>
	      <property name="numeric">True</property>
	      <property name="update_policy">GTK_UPDATE_ALWAYS</property>
	      <property name="snap_to_ticks">False</property>
	      <property name="wrap">False</property>
	      <property name="adjustment">1 0 10000 1 10 10</property>
	    </widget>
	    <packing>
	      <property name="left_attach">3</property>
	      <property name="right_attach">4</property>
	      <property name="top_attach">4</property>
	      <property name="bottom_attach">5</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>
	</widget>
	<packing>
	  <property name="padding">0</property>
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

Sprog::Gear::ImageText - Add a line of text to an image

=head1 DESCRIPTION

This is an experimental (proof-of-concept) gear for manipulating Image data in
Sprog.  Given a stream of data from an image file, it will add a line of text
and write out the resulting bitstream to the next downstream gear.

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
one line of text to the image.

I<Warning this is just a proof-of-concept implementation.  It will be replaced
with a more robust version soon>.

=head2 Properties

This gear has no properties:

=end :sprog-help-text

