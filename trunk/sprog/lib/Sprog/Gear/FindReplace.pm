package Sprog::Gear::FindReplace;

=begin sprog-gear-metadata

  title: Find and Replace
  type_in: P
  type_out: P
  keywords: grep pattern regex regular expression search

=end sprog-gear-metadata

=cut

use strict;

use base qw(
  Sprog::Gear
  Sprog::Gear::InputByLine
);

__PACKAGE__->declare_properties(
  pattern         => '',
  replacement     => '',
  ignore_case     => 1,
  global_replace  => 1,
);


sub prime {
  my $self = shift;

  my $pattern = $self->pattern;

  delete $self->{subst};
  if(defined($pattern) and $pattern ne '') {
    $pattern =~ s{/}{\\/}g;

    my $flags = $self->global_replace ? 'g' : '';
    $flags   .= $self->ignore_case    ? 'i' : '';

    my $replacement = $self->replacement;
    $replacement =~ s{/}{\\/}g;

    local($@);
    $self->{subst} = eval "sub { s/$pattern/$replacement/$flags }";
    if($@) {
      $self->app->alert("Error setting up find/replace", $@);
      delete $self->{subst};
      $@ = '';
    }
  }

  return $self->SUPER::prime;
}


sub line {
  my $self  = shift;
  local($_) = shift;

  &{$self->{subst}} if($self->{subst});

  $self->msg_out(data => $_);
}


sub dialog_xml {
  #return 'file:/home/grant/projects/sprog/glade/findreplace.glade';

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
	    <widget class="GtkEntry" id="PAD.pattern">
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
	      <property name="label" translatable="yes">Find Pattern:</property>
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
	      <property name="label" translatable="yes">Replace With:</property>
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
	      <property name="x_padding">5</property>
	      <property name="y_padding">5</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkEntry" id="PAD.replacement">
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
	      <property name="top_attach">1</property>
	      <property name="bottom_attach">2</property>
	      <property name="x_padding">5</property>
	      <property name="y_padding">5</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkVBox" id="vbox2">
	      <property name="visible">True</property>
	      <property name="homogeneous">False</property>
	      <property name="spacing">0</property>

	      <child>
		<widget class="GtkCheckButton" id="PAD.ignore_case">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Ignore case in pattern match (/i)</property>
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
		<widget class="GtkCheckButton" id="PAD.global_replace">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Replace globally (/g)</property>
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
	      <property name="right_attach">2</property>
	      <property name="top_attach">2</property>
	      <property name="bottom_attach">3</property>
	      <property name="x_options"></property>
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

Sprog::Gear::FindReplace - A find/replace filter

=head1 DESCRIPTION

This is a filter gear.  It uses 'pipe' connectors for both input and output,
reads a line at a time and performs a C<s/pattern/replacement/> on each line.
next gear depending on whether the line matched a pattern (regex).  The user
can choose to make the matching case sensitive or insensitive (C</i>) and
to perform multiple replacements in each line (C</g>).

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Find and Replace Gear

The 'Find and Replace' gear allows you to transform lines of text using a
pattern match along with replacement text.  This gear is only intended to work
with text, it probably won't do anything useful with binary data.

=head2 Properties

The find and replace gear has four properties:

=over 4

=item Find Pattern

Type a Perl regular expression in the entry box.  If you don't know what that
means, start with the
L<Introduction to Regular Expressions|Sprog::help::regex_intro>.

=item Replace With

Enter the text that you want inserted in place of the matched pattern.  (See
the 'cookbook' below).

=item Ignore case in pattern match

If you check this box, differences between upper and lower case letters will
not affect pattern matching.  For example, if your pattern was 'cat', a line
containing 'Cat' would match only if this box was checked.

=item Replace globally

If this box is B<not> checked, only the first match on each line will be
replaced.

If it is checked, all occurrences of the pattern match will be replaced.

=back

=head2 Find/Replace Cookbook

Here are some examples to get you going.

The simplest example is to replace all occurences of one word with another.
For example, to turn all occurrences of 'cat' into 'dog':

  Find Pattern: cat
  Replace With: dog

Of course that will match 'cat' wherever it appears so 'scatter' will become
'sdogter' - which might not be what you want.  To replace whole words, anchor
your match to the boundaries (beginning and end) of the word:

  Find Pattern: \bcat\b
  Replace With: dog

To delete a word, leave the replacement box empty:

  Find Pattern: \bcat\b
  Replace With:

To delete spaces at the start of a line:

  Find Pattern: ^\s+
  Replace With:

You can 'capture' a specific part of the match using round brackets and then
refer to it in the replacement text as C<$1>.  So to turn every occurrence of
'cat' into '*cat*':

  Find Pattern: \b(cat)\b
  Replace With: *$1*

Similarly you can use C<\U..\E> to force the characters in between to upper
case:

  Find Pattern: \b(cat)\b
  Replace With: \U$1\E

To turn a 4-digit year in a date into a 2-digit year:

  Find Pattern: (\d\d?/\d\d?/)\d\d(\d\d)
  Replace With: $1$2

=head2 Related Topics

If you need the full power of Perl's C<s/pattern/replacement/> syntax then
you can use a one liner in a L<Perl Code|Sprog::Gear::PerlCode> gear.

=end :sprog-help-text

