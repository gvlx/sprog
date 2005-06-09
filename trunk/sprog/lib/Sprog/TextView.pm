package Sprog::TextView;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  app
  gearview_class
));


use Scalar::Util qw(weaken);

sub new {
  my $class = shift;

  my $self = bless { @_, gears => { } }, $class;
  weaken($self->{app});

  my $app = $self->app;
  $app->inject('/app/view/gearview' => 'Sprog::TextGearView');
  $self->gearview_class($app->load_class('/app/view/gearview'));

  return $self;
}

sub apply_prefs         { return; }
sub set_window_title    { return; }
sub update_gear_view    { return; }
sub status_message      { return; }
sub running             { return; }


sub alert {
  my($self, $msg, $detail) = @_;

  print STDERR "$msg\n$detail\n";
  $self->app->quit;
}


sub add_gear_view {
  my($self, $gear) = @_;

  my $class = $self->gearview_class;
  my $app   = $self->app;
  my $gear_view = eval {
    my $suffix = $gear->view_subclass;
    if($suffix) {
      $class .= '::' . $suffix;
      $app->require_class($class);
    }

    $class->new(
      app    => $app,
      gear   => $gear,
    );
  };
  if($@) {
    $app->alert("Unable to create a $class object", $@);
    undef($@);
    return;
  }
  
  $self->{gears}->{$gear->id} = $gear_view;
}


sub gear_view_by_id {
  my($self, $id) = @_;

  return $self->{gears}->{$id};
}


1;

__END__


=head1 NAME

Sprog::TextView - a text-mode user interface for Sprog

=head1 DESCRIPTION

This class implements the 'view' logic for Sprog when it is invoked in 
C<--nogui> mode.

In C<--nogui> mode, Sprog can load and run machine files with a number of
limitations:

=over 4

=item *

There is no facility for interacting with a machine.  In particular, you
cannot build a machine in C<--nogui> mode.

=item *

Not all gears support a C<--nogui> view.  Any gears which interact with the
user while a machine is running are unlikely to work.

=back

=head1 PREREQUISITES

When Sprog is run in C<--nogui> mode, it does not require the L<Gtk2> classes,
but it does require C<Glib>.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut

