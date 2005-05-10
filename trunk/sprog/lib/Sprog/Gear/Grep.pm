package Sprog::Gear::Grep;

use strict;

use base qw(
  Sprog::Gear
  Sprog::Gear::InputByLine
);

__PACKAGE__->declare_properties(
  pattern       => undef,
  ignore_case   => 1,
  invert_match  => 0,
);


sub title { 'Pattern Match' };


sub prime {
  my $self = shift;

  my $pattern = $self->pattern;

  delete $self->{regex};
  if(defined($pattern) and $pattern ne '') {
    if($self->ignore_case) {
      $self->{regex} = qr/$pattern/i;
    }
    else {
      $self->{regex} = qr/$pattern/;
    }
  }

  return $self->SUPER::prime;
}


sub line {
  my($self, $line) = @_;

  if(my $regex = $self->{regex}) {
    return unless($line =~ $regex ^ ($self->{invert_match} ? 1 : 0));
  }

  $self->msg_out(data => $line);
}


sub dialog_xml {
#  return 'file:/home/grant/projects/sprog/glade/grep.glade';

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
	  <property name="n_rows">2</property>
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
	      <property name="label" translatable="yes">Pattern:</property>
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
		<widget class="GtkCheckButton" id="PAD.ignore_case">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Ignore case in pattern match</property>
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
		<widget class="GtkCheckButton" id="PAD.invert_match">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Pass all lines except matches</property>
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
	      <property name="top_attach">1</property>
	      <property name="bottom_attach">2</property>
	      <property name="x_padding">20</property>
	      <property name="x_options"></property>
	      <property name="y_options">fill</property>
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

Sprog::Gear::Grep - A pattern match filter

=head1 DESCRIPTION

This is a filter gear.  It uses 'pipe' connectors for both input and output,
reads a line at a time and either discards each line or passes it down to the
next gear depending on whether the line matched a pattern (regex).  The user
can choose to include or exclude lines which match the pattern and can chose to
make the matching case sensitive or insensitive.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=head1 HELP VIEWER TEXT

=for sprog-help-text

=head1 Pattern Match Gear

The 'Pattern Match' gear allows you to filter lines of text using a pattern
match.  This gear is only intended to work with text, it probably won't do
anything useful with binary data.

If a line of data matches the selected pattern, the whole line will be passed
through, not just the bit that matches.

=head2 Properties

The pattern match gear has three properties:

=over 4

=item Pattern

Type a Perl 5 regular expression (more detail below) in the entry box.

=item Ignore case in pattern match

If you check this box, differences between upper and lower case letters will
not affect pattern matching.  For example, if your pattern was 'cat', a line
containing 'Cat' would match only if this box was checked.

=item Pass all lines except matches

If you check this box, lines which match the pattern will be discarded and only
lines which do not match will be passed through.

=back

=head2 Perl 5 Regular Expressions

A 'regular expression' is just a fancy name for a pattern.  You're probably
already familiar with filename patterns like 'C<*.doc>'.  Perl 5 regular
expressions are similar but much more powerful.  Here's a brief introduction
and some examples to get you started.

=head3 Plain Text

The simplest pattern is just plain text.  For example, this pattern ...

  cat

... will match any line containing a 'c' followed by an 'a' followed by a 't'.
So all these lines would match:

  The cat sat on the mat
  He picked up the catcher's mitt
  She scattered rose petals in the wind

But this line ...

  Cat Doors - $35 each

... would not match unless you checked the 'ignore case' box.

I<Note: you don't need to say 'C<*cat*>' and in fact it would be a mistake
to do so.  We'll get to stars shortly>.


=head3 Character Classes

You can use square brackets to specify a list of characters that should
match.  For example, this pattern ...

  [bcr]at

... will match any line containing either a 'b', a 'c' or an 'r' followed by
an 'a' followed by a 't'.  So all these lines would match:

  The cat sat on the mat
  He picked up the bat
  The gazed into the crater

But these would not:

  The hat sat on the mat
  canned flat bacon rashers

You can use '-' to specify a range of characters.  For example, this pattern
will match any of the first ten letters of the (english) alphabet:

  [a-j]

If the very first character in the square brackets is a '^' then it will match
any character this is B<not> in the list.  For example:

  [^bc]at

Will match 'hat' and 'mat' but not 'bat' or 'cat'.
  

=head3 Predefined Character Classes

There are a number of predefined character classes:

  \d   [0-9]         any digit
  \s   [ \t\r\n\f]   any 'whitespace' character
  \w   [a-zA-Z0-9_]  any letter, digit or underscore

  \D   [^0-9]        anything except a digit
  \S   [^\s]         anything except whitespace
  \W   [^\w]         anything except a letter, digit or underscore

So this pattern ...

  \d\dth

... would match any line containing two digits followed by 'th', such as:

  the 19th hole

The '.' can be thought of as a class which matches any character.  So for
example 'C<p.t>' would match 'pet', 'pot', 'p8t' and 'p@t'.  It would not match
'pt'.

=head3 Matching Multiple Times

If you wanted to match any line containing 5 consecutive 'W' characters, you
could use this:

  WWWWW

or this:

  W{5}

If you wanted to match 'bet' and 'beet' but not 'beeet', you could use this:

  be{1,2}t

I<Note: the number or numbers in the curly brackets only apply to the character
or character class immediately before the '{'.  In the above example it will match at least 1 but no more than 2 consecutive 'e's>.

Often you want to include an optional character in a match, you could match on
zero or one occurences:

  pots{0,1}

which will match 'pot' or 'pots' (and also 'potscrub').  This is so common it
has a shorthand form - just replace 'C<{0,1}>' with '?' which means exactly
the same thing:

  pots?

There are two other important shorthand forms.  '*' mean 0 or more so this:

  po*t

is the same as:

  po{0,}t

which will match 'pt', 'pot', 'poot', etc.

The other import form is '+' meaning one or more matches:

  po+t

will match 'pot', 'poot', etc.


=head3 Anchoring a Match

If the very first character in your pattern is '^' then what follows is
'anchored' to the start of the line.  For example ...

  ^pot

... will match these lines:

  potato
  potentially

but not these:

  a pot-plant
  spotted

Similarly, '$' can be used to anchor to the end of the line, so ...

  end$

... will match:

  Max is my friend

but not:

  My friend is Max

You can use both '^' and '$' in the same pattern.  Here for example is a
pattern that matches lines which start with a capital letter and end with an
exclamation point:

  ^[A-Z].*!$

=head2 More Information

That's far more information than you can be expected to absorb in one sitting,
so we'll stop there.  The best way to become proficient with regular
expressions is to use them and Sprog is an ideal tool for trying out different
patterns and different data.

This quick introduction has only scratched the surface of what's possible in a
Perl 5 regular expression.  The official Perl 5 regular expression tutorial is
at: L<http://perldoc.perl.org/perlretut.html>.

A web search will locate many helpful pages:
L<http://www.google.com/search?q=perl+regular+expression+tutorial>.

There are also a number of books on the subject.

The L<Find and Replace|Sprog::Gear::FindReplace> gear also uses Perl 5
regular expressions.
