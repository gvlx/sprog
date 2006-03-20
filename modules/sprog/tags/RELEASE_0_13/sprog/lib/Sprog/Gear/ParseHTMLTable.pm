package Sprog::Gear::ParseHTMLTable;

=begin sprog-gear-metadata

  title: Parse HTML Table
  type_in: P
  type_out: A

=end sprog-gear-metadata

=cut

use strict;

use base qw(
  Sprog::Gear::SlurpFile
  Sprog::Gear
);

use XML::LibXML;

__PACKAGE__->declare_properties(
  selector => 1,
);


sub file_data {
  my($self, $data) = @_;

  return unless length $data;

  my $doc = eval {
    local($^W) = 0;

    my $parser = XML::LibXML->new();
    $parser->recover(1);
    $parser->parse_html_string($data);
  };
  return $self->alert('Error parsing HTML', "$@") if $@;

  my $path  = $self->selector;
  my $index = 0;
  if($path =~ /^\d+$/) {
    $index = $path - 1;
    $path = '//table';
  }
  my $table = ($doc->findnodes($path))[$index];
  return unless $table;

  foreach my $tr ($table->findnodes('./tr|./*/tr')) {
    my @cells;
    foreach my $td ($tr->findnodes('./th|./td')) {
      push @cells, $td->to_literal;
    }
    next unless @cells;
    $self->msg_out(row => \@cells);
  }

}


sub dialog_xml {
#  return 'file:/home/grant/projects/sf/sprog/glade/htmltable.glade';
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
	  <property name="n_columns">2</property>
	  <property name="homogeneous">False</property>
	  <property name="row_spacing">0</property>
	  <property name="column_spacing">0</property>

	  <child>
	    <widget class="GtkEntry" id="PAD.selector">
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
	      <property name="right_attach">2</property>
	      <property name="top_attach">0</property>
	      <property name="bottom_attach">1</property>
	      <property name="x_padding">5</property>
	      <property name="y_padding">5</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="label1">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Table: </property>
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

Sprog::Gear::ParseHTMLTable - extract rows of data from an HTML table

=head1 DESCRIPTION

Transforms an HTML table into a a series of output 'row' events corresponding
to the contents of each cell in each row of the table.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Parse HTML Table Gear

This gear reads an HTML document from its 'pipe' input connector and identifies
one C<< <table> >> in the document (see below for the table selector property).
The contents of the table are then sent out the 'list' connector as rows of
field values.

=head2 Properties

This gear has only one property - the table selector.  The default value is
'1' which means the first table in the document.  You can use a different
numeric index or an XPath expression as shown in the examples below.

=head2 Selector Cookbook

The table selector can be either a number, or an XPath expression.  XPath is
very powerful, but it can be a bit intimidating so here are some examples to
get you going.

If your HTML document contained a table tag like this:

  <table id='products'>

You could select that table with this XPath expression:

  //table[@id='products']

In English, we'd read that expression as "I<find all C<< <table> >> elements at
any level of the document, which contain an 'id' attribute with the value
'products'>".  Although the expression will select all tables which match, this
gear only reads the first one.

If the table you were interested did not have an 'id' attribute, but was
contained in a C<< <div> >> that had a 'class' of 'content', you could select
the table with this expression:

  //div[@class='content']/table

In English, we'd read that as "I<find all C<< <table> >> elements contained
directly inside C<< <div> >> elements that have a 'class' attribute with the
value 'content'>".

It is also possible to select elements based on the text contained within them.
For example, the first cell in the first row of a table might be a C<< <th> >>
containing the text 'Surname'.  We could identify a C<< <th> >> containing that
text with this expression:

  //th[contains(text(), 'Surname')]

but we're only interested in the one that's the first in the row:

  //th[position() = 1 and contains(text(), 'Surname')]

or, since the "position() =" bit is optional:

  //th[1 and contains(text(), 'Surname')]

but we're only interested in the one that's in the first row:

  //tr[1]/th[1 and contains(text(), 'Surname')]

but that selects the C<< <th> >> and we actually want the C<< <table> >> that
contains it.  So the final selector would look like this:

  //table[./tr[1]/th[1 and contains(text(), 'Surname')]]

In English: "I<the table in which the first C<< <th> >> in the first C<< <tr> >>
contains the text 'Surname'>".

Note: text matches in XPath are case sensitive and current versions of XPath
don't really support case-insensitive matching.

=head2 See Also:

For an XPath tutorial and workshop: L<http://www.zvon.org/xxl/XPathTutorial/General/examples.html>.



=end :sprog-help-text
