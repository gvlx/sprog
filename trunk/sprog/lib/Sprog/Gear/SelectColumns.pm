package Sprog::Gear::SelectColumns;

=begin sprog-gear-metadata

  title: Select Columns
  type_in: A
  type_out: A

=end sprog-gear-metadata

=cut

use strict;
use warnings;

use base qw(Sprog::Gear);

__PACKAGE__->declare_properties(
  columns => '',
  base => 1,
);


sub engage {
  my $self = shift;

  delete $self->{_colspec};
  local($_) = $self->columns;
  return $self->alert('You must select some columns') unless(/\S/);
  
  s/\s+//g;
  my $base = $self->base;
  my $more = qr/(?:,(.*))?/;
  my @ranges;
  while(length($_)) {
    my($start, $end, $rest);
    if(/^(\d+)$more$/o) {
      ($start, $end, $rest) = ($1-$base, $1-$base, $2);
    }
    elsif(/^-(\d+)$more$/o) {
      ($start, $end, $rest) = (0, $1-$base, $2);
    }
    elsif(/^(\d+)-(\d+)$more$/o) {
      return $self->alert("Error in column list at: '$1-$2'") if $2 < $1;
      ($start, $end, $rest) = ($1-$base, $2-$base, $3);
    }
    elsif(/^(\d+)-$more$/o) {
      ($start, $end, $rest) = ($1-$base, '*', $2);
    }
    else {
      return $self->alert("Error in column list at: '$_'");
    }
    return $self->alert("Error in column list at: '$_'") if $start < 0;
    push @ranges, [ $start, $end ];
    last unless defined $rest;
    $_ = $rest;
  }
  $self->{_colspec} = \@ranges;
  $self->{_slices} = {};
}


sub row {
  my($self, $r) = @_;

  my $slice = $self->{_slices}->{$#$r} ||= $self->_slice($#$r);
  $self->msg_out(row => [ map { defined($_) ? $_ : '' } @{$r}[@$slice] ]);
}


sub _slice {
  my($self, $last) = @_;

  return [ 
    map {
      $_->[1] eq '*'
      ? ($_->[0]..$last) 
      : ($_->[0]..$_->[1])
    } @{$self->{_colspec}} 
  ];
}


sub dialog_xml {
#  return 'file:/home/grant/projects/sf/sprog/glade/select_cols.glade';
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
	  <property name="n_rows">3</property>
	  <property name="n_columns">2</property>
	  <property name="homogeneous">False</property>
	  <property name="row_spacing">0</property>
	  <property name="column_spacing">0</property>

	  <child>
	    <widget class="GtkEntry" id="PAD.columns">
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
	      <property name="label" translatable="yes">Columns:</property>
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
	    <widget class="GtkVBox" id="vbox1">
	      <property name="visible">True</property>
	      <property name="homogeneous">False</property>
	      <property name="spacing">0</property>

	      <child>
		<widget class="GtkRadioButton" id="PAD.base.1">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Count from first column = 1</property>
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
		<widget class="GtkRadioButton" id="PAD.base.0">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Count from first column = 0</property>
		  <property name="use_underline">True</property>
		  <property name="relief">GTK_RELIEF_NORMAL</property>
		  <property name="focus_on_click">True</property>
		  <property name="active">False</property>
		  <property name="inconsistent">False</property>
		  <property name="draw_indicator">True</property>
		  <property name="group">PAD.base.1</property>
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
	      <property name="x_padding">20</property>
	      <property name="x_options"></property>
	      <property name="y_options">fill</property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="label1">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">eg: 2-4,1,5</property>
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

__END__


=head1 NAME

Sprog::Gear::SelectColumns - select columns in each row

=head1 DESCRIPTION

Passes only the selected columns between the list input and the list output.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Select Columns

This gear allows you to pass through selected columns from the 'list' input
connector to the 'list' output connector.

You might find this useful for:

=over 4

=item *

re-ordering columns

=item *

discarding columns

=item *

duplicating columns

=back

=head2 Properties

=over 4

=item Columns

Enter the list of columns you want, in the order you want them.  Multiple
columns should be separated with commas and ranges should be specified as
I<n-n>.

=item Base

There are two options for numbering the columns.  If you're not a Perl
programmer, you'll think this is crazy and wonder why anyone would select
anything other than numbering from 1 (the default).  If you I<are> a Perl
programmer, you'll think this is crazy and wonder why anyone would select
anything other than numbering from 0.

=back

=head2 Columns Cookbook

All these examples assume a numbering base of 1.

This will select only the second column:

  2

This will select columns 4, 5 and 6 followed by column 1 (all other columns
will be discarded):

  4-6,1

This will reverse the first two columns, and pass the remaining columns through
untouched:

  2,1,3-

Similarly, this will pass the first three columns through untouched, pass two
copies of the fifth column and discard the rest:

  -3,5,5

=end :sprog-help-text

