package Sprog::GlibEventLoop;


use Glib ();

my $loop;

sub loop { $loop ||= Glib::MainLoop->new; }

sub run  { loop()->run;  }
sub quit { loop()->quit; }


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

Sprog::GlibEventLoop - methods used to interface Sprog to the Glib event loop

=head1 SYNOPSIS

  my $event_loop = $factory->load_class('/app/eventloop');

  $event_loop->add_idle_handler(sub { $event_loop->quit });

  $event_loop->run;


=head1 DESCRIPTION

This class uses L<Glib> to provide an event loop that does not require Gtk or a
graphical display. 

The Sprog application uses L<Sprog::GtkEventLoop> which uses this class as a
base but overrides the C<run()> and C<quit()> methods to link into the Gtk
event loop rather than the lower level Glib event loop.

This class is used during testing by test scripts that don't require a display.
In theory, it could also be used by Sprog in 'no-display' mode - if such a
mode was ever implemented.


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

=head2 add_io_writer ( fh, sub_ref )

Define a callback that should be called when the specified file is ready for
writing.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut


