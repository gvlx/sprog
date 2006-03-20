package Sprog::Gear::InputByPara;

sub data {
  my($self, $buf) = @_;

  my $para_method = $self->can('para') or die "Gear has no 'para' method";

  my $i = 0;
  my $j = index($buf, "\n\n");

  my $last = length($buf) - 1;
  return if $last < 0;

  while($j > -1) {
    $para_method->($self, substr($buf, $i, $j-$i+1));
    $i = $j + 1;
    return if($i > $last);                      # buffer ended with a \n\n
    $j = index($buf, "\n\n", $i);
  }

  my $msg_queue = $self->msg_queue;

  return $self->requeue_message_delayed(data => substr($buf, $i)) 
    unless(@$msg_queue);                        # wait for next message

  return $para_method->($self, substr($buf, $i))
    unless($msg_queue->[0]->[0] eq 'data');     # just send incomplete para

  my $more_data = shift @$msg_queue;            # concatenate with next message
  return $self->data(substr($buf, $i) . $more_data->[1]);
}


1;

=head1 NAME

Sprog::Gear::InputByPara - a 'mixin' class for gears reading input by empty line-separated paragraphs

=head1 SYNOPSIS

  use base qw(
    Sprog::Gear::InputByPara
    Sprog::Gear
  );

=head1 DESCRIPTION

This mixin is for use by gears which use a 'pipe' style of input connector but
want to process the input blank-line-delimited paragraph-by-paragraph.  

It defines a C<data> method which passes each paragraph of input to the gear's
C<para> method.

=head1 METHODS

=head2 data ( buffer )

Extracts paragraphs from the supplied buffer and passes them to the C<para>
method.  Paragraphs are assumed to be separated by blank lines.  A line which
contains only spaces is I<not> considered a blank line.

A buffer which ends with some text that has no paragraph terminator, will be
handled as follows:

=over 4

=item *

if there are no more messages queued, the remaining text is re-queued until
a subsequent message is received

=item *

if the next queued message is also a C<data> message, the remaining text will
be prepended to the next buffer

=item *

otherwise (if the next message is not a C<data> message), the incomplete
paragraph will be passed to the gear's C<para> method

=back

A class that uses this mixin is expected to implement a C<para> method.

=head1 ACKNOWLEDGEMENTS

Chris Benson had the original idea for this gear and created the initial
implementation by adapting the L<Sprog::Gear::InputByLine> class.

=head1 COPYRIGHT 

Copyright 2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut


