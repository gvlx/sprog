package Sprog::GtkEventLoop;


use Gtk2 '-init';
use Glib ();

sub run  { Gtk2->main;      }
sub quit { Gtk2->main_quit; }


sub add_timeout {
  my($class, $delay, $sub) = @_;

  return Glib::Timeout->add($delay, $sub);
}


sub add_idle_handler {
  my($class, $sub) = @_;

  return Glib::Idle->add($sub);
}


sub add_io_reader {
  my($class, $fh, $sub) = @_;

  return Glib::IO->add_watch(fileno($fh), ['in', 'err', 'hup'], $sub);
}


sub add_io_writer {
  my($class, $fh, $sub) = @_;

  return Glib::IO->add_watch(fileno($fh), ['out', 'err', 'hup'], $sub);
}


1;

__END__

=head1 NAME

Sprog::GtkEventLoop - methods used to interface Sprog to the GTK event Loop

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

=head2 add_timeout ( delay, sub_ref )

Define a callback that should be called after a specified delay (milliseconds).

=head2 add_idle_handler ( sub_ref )

Define a callback that should be called when no other events are waiting.

=head2 add_io_reader ( fh, sub_ref )

Define a callback that should be called when the specified file is ready for
reading.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut


