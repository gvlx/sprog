package Sprog::GtkEventLoop;


use Gtk2 '-init';

use base qw(Sprog::GlibEventLoop);

sub run  { Gtk2->main;      }
sub quit { Gtk2->main_quit; }

1;

__END__

=head1 NAME

Sprog::GtkEventLoop - methods used to interface Sprog to the Gtk2 event Loop

=head1 SYNOPSIS

  my $event_loop = $factory->load_class('/app/eventloop');

  $event_loop->add_idle_handler(sub { $event_loop->quit });

  $event_loop->run;


=head1 DESCRIPTION

This class provides the interface methods between Sprog and the Gtk2 event
loop.


=head1 METHODS

=head2 run ( )

Enter the main loop.

=head2 quit ( )

Exit the main loop.

=head1 INHERITED METHODS

The following methods are inherited from L<Sprog::GlibEventLoop>:

=over 4

=item add_timeout ( delay, sub_ref )

=item add_idle_handler ( sub_ref )

=item add_io_reader ( fh, sub_ref )

=item add_io_writer ( fh, sub_ref )

=back

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut


