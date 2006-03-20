package Sprog::TextGearView::TextWindow;

use base qw(Sprog::TextGearView);

sub clear { return; }

sub add_data {
  my($self, $data) = @_;

  print $data;
}


1;


__END__


=head1 NAME

Sprog::TextGearView::TextWindow - custom text-mode view for Sprog::Gear::TextWindow

=head1 DESCRIPTION

This class implements the 'view' logic for the L<Sprog::Gear::TextWindow> gear.
Rather than displaying text in a scrolling window (as
L<Sprog::GtkGearView::TextWindow> does), this class simply outputs text to
STDOUT.

=head1 INSTANCE METHODS

=head2 clear ( )

This method does nothing.

=head2 add_data ( data )

Takes the supplied data (presumably text) and outputs it to STDOUT.

=head1 COPYRIGHT 

Copyright 2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut

